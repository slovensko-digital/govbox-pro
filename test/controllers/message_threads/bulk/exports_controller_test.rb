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

      test 'update persists message_direction setting' do
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'message_direction' => 'outbox' } } }
        assert_equal 'outbox', @export.reload.settings['message_direction']
      end

      test 'start with message_direction inbox enqueues ExportJob' do
        assert_enqueued_with(job: ExportJob) do
          post :start, params: { export_id: @export.id, export: { settings: { 'messages' => '1', 'default' => '1', 'message_direction' => 'inbox' } } }
        end
      end

      test 'edit renders message_direction radio buttons' do
        get :edit, params: { id: @export.id }
        assert_select "input[type=radio][name='export[settings][message_direction]']", count: 3
      end

      test 'edit renders date range inputs' do
        get :edit, params: { id: @export.id }
        assert_select "input[type=date][name='export[settings][delivered_at_from]']", count: 1
        assert_select "input[type=date][name='export[settings][delivered_at_to]']", count: 1
      end

      test 'update persists delivered_at_from date setting' do
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'delivered_at_from' => '2025-01-01' } } }
        assert_equal "2025-01-01", @export.reload.settings['delivered_at_from']
      end

      test 'update persists delivered_at_to date setting' do
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'delivered_at_to' => '2025-06-30' } } }
        assert_equal "2025-06-30", @export.reload.settings['delivered_at_to']
      end

      test 'update with from > to returns unprocessable_content' do
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'delivered_at_from' => '2025-06-30', 'delivered_at_to' => '2025-01-01' } } }
        assert_response :unprocessable_content
      end

      test 'start with date range enqueues ExportJob' do
        assert_enqueued_with(job: ExportJob) do
          post :start, params: { export_id: @export.id, export: { settings: { 'messages' => '1', 'default' => '1', 'delivered_at_from' => '2025-01-01', 'delivered_at_to' => '2025-06-30' } } }
        end
      end
    end
  end
end
