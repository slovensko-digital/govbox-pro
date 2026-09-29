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

      test 'start with partial settings merges them and starts when valid' do
        post :start, params: { export_id: @export.id, export: { settings: { 'messages' => '0' } } }
        assert_redirected_to root_path
        @export.reload
        assert_equal true, @export.settings['summary'], 'untouched summary stays true after merge'
        assert_equal false, @export.settings['messages'], 'explicit zero disables messages'
        assert_equal({ 'default' => 'A', 'x' => 'Y' }, @export.settings['templates'], 'unsubmitted nested settings are preserved')
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

      test 'edit renders hidden unchecked-value fields for settings checkboxes' do
        get :edit, params: { id: @export.id }
        %w[summary messages pdf default].each do |flag|
          assert_select "input[type=hidden][name='export[settings][#{flag}]'][value='0']", count: 1
        end
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

      test 'update with a complete form payload stores exactly the submitted settings' do
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'messages' => '1', 'pdf' => '0', 'default' => '1', 'message_direction' => 'outbox', 'delivered_at_from' => '', 'delivered_at_to' => '', 'by_form' => { 'DPHv20' => '0' }, 'templates' => { 'default' => 'A', 'x' => 'Y' } } } }
        assert_redirected_to edit_message_threads_bulk_export_path(@export)
        assert_equal({ 'summary' => true, 'messages' => true, 'pdf' => false, 'default' => true, 'message_direction' => 'outbox', 'delivered_at_from' => nil, 'delivered_at_to' => nil, 'by_form' => { 'DPHv20' => false }, 'templates' => { 'default' => 'A', 'x' => 'Y' } }, @export.reload.settings)
      end

      test 'update preserves per-form settings not present in submission' do
        @export.update!(settings: { 'summary' => true, 'messages' => true, 'by_form' => { 'DPHv20' => true }, 'templates' => { 'default' => 'A', 'DPHv20' => 'DPH TPL' } })
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'messages' => '1', 'templates' => { 'default' => 'A' } } } }
        @export.reload
        assert_equal true, @export.settings.dig('by_form', 'DPHv20'), 'by_form toggle for absent form is preserved'
        assert_equal 'DPH TPL', @export.settings.dig('templates', 'DPHv20'), 'template for absent form is preserved'
      end

      test 'update with explicit zero disables a per-form toggle' do
        @export.update!(settings: { 'summary' => true, 'messages' => true, 'by_form' => { 'DPHv20' => true } })
        patch :update, params: { id: @export.id, export: { settings: { 'summary' => '1', 'messages' => '1', 'by_form' => { 'DPHv20' => '0' } } } }
        assert_equal false, @export.reload.settings.dig('by_form', 'DPHv20'), 'explicit zero takes effect on merge'
      end

      test 'create inherits settings from last created export' do
        user = @export.user
        @export.update!(settings: { 'summary' => true, 'messages' => true, 'message_direction' => 'inbox' })

        Export.create!(user: user, message_thread_ids: [], settings: { 'summary' => true, 'messages' => true, 'message_direction' => 'outbox', 'templates' => { 'default' => 'A', 'x' => 'Y' } })

        post :create, params: { message_thread_ids: [] }
        new_export = user.exports.order(:id).last
        assert_redirected_to edit_message_threads_bulk_export_path(new_export)
        assert_equal 'outbox', new_export.settings['message_direction'], 'new export inherits last created export'
        assert_equal true, new_export.settings['summary']
        assert_equal true, new_export.settings['messages']
        assert_equal({ 'default' => 'A', 'x' => 'Y' }, new_export.settings['templates'])
      end

      test 'create uses defaults when user has no exports' do
        user = @export.user
        user.exports.delete_all
        post :create, params: { message_thread_ids: [] }
        new_export = user.exports.order(:id).last
        assert_equal true, new_export.settings['default']
      end
    end
  end
end
