require 'test_helper'

class VersionsControllerTest < ActionController::TestCase
  context 'GET to index' do
    setup do
      @rubygem = create(:rubygem)
      @versions = (1..5).map do |version|
        create(:version, :rubygem => @rubygem)
      end

      get :index, :rubygem_id => @rubygem.name
    end

    should respond_with :success
    should render_template :index

    should "show all related versions" do
      @versions.each do |version|
        assert page.has_content?(version.number)
      end
    end
  end

  context 'GET to index as an atom feed' do
    setup do
      @rubygem = create(:rubygem)
      @versions = (1..5).map do |version|
        create(:version, :rubygem => @rubygem)
      end
      @rubygem.reload

      get :index, :rubygem_id => @rubygem.name, :format => "atom"
    end

    should respond_with :success

    should "render correct gem information in the feed" do
      assert_select "feed > title", :count => 1, :text => /#{@rubygem.name}/
      assert_select "feed > updated", :count => 1, :text => @rubygem.updated_at.iso8601
    end

    should "render information about versions" do
      @versions.each do |v|
        assert_select "entry > title", :count => 1, :text => v.to_title
        assert_select "entry > link[href='#{rubygem_version_url(v.rubygem, v.slug)}']", :count => 1
        assert_select "entry > id", :count => 1, :text => rubygem_version_url(v.rubygem, v.slug)
        # assert_select "entry > updated", :count => @versions.count, :text => v.created_at.iso8601
      end
    end
  end

  context "GET to index for gem with no versions" do
    setup do
      @rubygem = create(:rubygem)
      get :index, :rubygem_id => @rubygem.name
    end

    should respond_with :success
    should render_template :index
    should "show not hosted notice" do
      assert page.has_content?('This gem is not currently hosted')
    end
    should "not show checksum" do
      assert page.has_no_content?('Sha 256 checksum')
    end
  end

  context "On GET to show" do
    setup do
      @latest_version = create(:version, :built_at => 1.week.ago, :created_at => 1.day.ago)
      @rubygem = @latest_version.rubygem
      @versions = (1..5).map do |_|
        FactoryGirl.create(:version, :rubygem => @rubygem)
      end
      get :show, :rubygem_id => @rubygem.name, :id => @latest_version.number
    end

    should respond_with :success
    should render_template "rubygems/show"
    should "render info about the gem" do
      assert page.has_content?(@rubygem.name)
    end
    should "render the specified version" do
      assert page.has_content?(@latest_version.number)
    end
    should "render other related versions" do
      @versions.each do |version|
        assert page.has_content?(version.number)
      end
    end
    should "render the checksum version" do
      assert page.has_content?(@latest_version.sha256_hex)
    end
  end
end
