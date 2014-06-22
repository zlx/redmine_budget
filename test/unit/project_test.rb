require File.expand_path('../../test_helper', __FILE__)

class ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :roles, :wages

  test "when creating a sub-project (project with a parent), budget settings are being duplicated" do
    parent = Project.find(1)

    child = Project.create!(name: "some-name", identifier: 'some-name', parent: parent)
    assert_equal 1, parent.wages.count
    assert_equal child.wages.count, parent.wages.count
    assert_equal child.wages.first.attributes.except("id", "project_id"), parent.wages.first.attributes.except("id", "project_id")
  end
end
