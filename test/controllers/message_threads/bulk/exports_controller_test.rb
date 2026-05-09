require 'test_helper'

module MessageThreads
  module Bulk
    class ExportsControllerTest < ActionController::TestCase
      include ActiveJob::TestHelper
      tests MessageThreads::Bulk::ExportsController
      fixtures :users, :boxes

      setup do
        Current.user = users(:basic)
        session[:login_expires_at] = Time.now + 1.day
        session[:user_id] = Current.user.id
        session[:tenant_id] = Current.user.tenant_id
        session[:box_id] = boxes(:ssd_main).id
        @export = Export.create!(user: Current.user, message_thread_ids: [1,2], settings: { 'summary' => true, 'messages' => true, 'templates' => { 'default' => 'A', 'x' => 'Y' } })
      end

      def start_path
        message_threads_bulk_export_start_path(@export)
      end

      test 'start succeeds with existing valid settings when no new settings posted' do
        post :start, params: { export_id: @export.id }
        assert_redirected_to root_path
      end

      test 'start with partial settings overwrites settings and renders inline errors when invalid (no persistence)' do
        post :start, params: { export_id: @export.id, export: { settings: { 'messages' => '0' } } }
        assert_response :unprocessable_content
        @export.reload
        assert_equal true, @export.settings['summary'], 'invalid start should not persist: summary remains true'
        assert_equal true, @export.settings['messages'], 'invalid start should not persist: messages remains true'
      end

      test 'start fails when invalid (no summary, no messages) after merge' do
        @export.update!(settings: { 'summary' => false, 'messages' => true })
        post :start, params: { export_id: @export.id, export: { settings: { 'messages' => '0' } } }
        assert_response :unprocessable_content
        @export.reload
        assert_equal true, @export.settings['messages'], 'invalid combination should not persist (messages should remain true)'
      end

      test 'start fails when both options set to zero in single request' do
        assert @export.settings['summary']
        assert @export.settings['messages']
        post :start, params: { export_id: @export.id, export: { settings: { 'summary' => '0', 'messages' => '0' } } }
        assert_response :unprocessable_content
      end

      test 'start enqueues job and creates notification' do
        user = @export.user
        count_before = user.notifications.count
        assert_enqueued_with(job: ExportJob) do
          post :start, params: { export_id: @export.id }
        end
        assert_equal count_before + 1, user.notifications.count
        started_types = user.notifications.where(export: @export).pluck(:type)
        assert_includes started_types, 'Notifications::ExportStarted'

        perform_enqueued_jobs

        finished_types = user.notifications.where(export: @export).pluck(:type)
        assert_equal count_before + 2, finished_types.size
        assert_includes finished_types, 'Notifications::ExportFinished'
      end

      test 'invalid start does not persist invalid combination' do
        post :start, params: { export_id: @export.id, export: { settings: { 'summary' => '0', 'messages' => '0' } } }
        assert_response :unprocessable_content
        @export.reload
        refute(@export.settings['summary'] == false && @export.settings['messages'] == false)
      end
    end
  end
end
