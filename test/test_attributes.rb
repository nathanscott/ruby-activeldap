require 'al-test-utils'

class TestAttributes < Test::Unit::TestCase
  include AlTestUtils

  priority :must

  priority :normal
  def test_to_real_attribute_name
    user = @user_class.new("user")
    assert_equal("objectClass",
                 user.__send__(:to_real_attribute_name, "objectclass"))
    assert_equal("objectClass",
                 user.__send__(:to_real_attribute_name, "objectclass", true))
    assert_nil(user.__send__(:to_real_attribute_name, "objectclass", false))
  end

  def test_protect_object_class_from_mass_assignment
    classes = @user_class.required_classes + ["inetOrgPerson"]
    user = @user_class.new(:uid => "XXX", :object_class => classes)
    assert_equal(["inetOrgPerson"],
                 user.classes -  @user_class.required_classes)

    user = @user_class.new(:uid => "XXX", :object_class => ['inetOrgPerson'])
    assert_equal(["inetOrgPerson"],
                 user.classes -  @user_class.required_classes)

    user = @user_class.new("XXX")
    assert_equal([], user.classes -  @user_class.required_classes)
    user.attributes = {:object_class => classes}
    assert_equal([], user.classes -  @user_class.required_classes)
  end

  def test_normalize_attribute
    assert_equal(["usercertificate", [{"binary" => []}]],
                 ActiveLdap::Base.normalize_attribute("userCertificate", []))
    assert_equal(["usercertificate", [{"binary" => []}]],
                 ActiveLdap::Base.normalize_attribute("userCertificate", nil))
    assert_equal(["usercertificate", [{"binary" => "BINARY DATA"}]],
                 ActiveLdap::Base.normalize_attribute("userCertificate",
                                                      "BINARY DATA"))
    assert_equal(["usercertificate", [{"binary" => ["BINARY DATA"]}]],
                 ActiveLdap::Base.normalize_attribute("userCertificate",
                                                      {"binary" =>
                                                        ["BINARY DATA"]}))
  end

  def test_unnormalize_attribute
    assert_equal({"sn" => ["Surname"]},
                 ActiveLdap::Base.unnormalize_attribute("sn", ["Surname"]))
    assert_equal({"userCertificate;binary" => []},
                 ActiveLdap::Base.unnormalize_attribute("userCertificate",
                                                        [{"binary" => []}]))
    assert_equal({"userCertificate;binary" => ["BINARY DATA"]},
                 ActiveLdap::Base.unnormalize_attribute("userCertificate",
                                                        [{"binary" =>
                                                           ["BINARY DATA"]}]))
  end

  def test_attr_protected
    user = @user_class.new(:uid => "XXX")
    assert_equal("XXX", user.uid)
    user.attributes = {:uid => "ZZZ"}
    assert_equal("XXX", user.uid)

    user = @user_class.new(:sn => "ZZZ")
    assert_equal("ZZZ", user.sn)

    user = @user_class.new(:uid => "XXX", :sn => "ZZZ")
    assert_equal("XXX", user.uid)
    assert_equal("ZZZ", user.sn)

    @user_class.attr_protected :sn
    user = @user_class.new(:sn => "ZZZ")
    assert_nil(user.sn)

    sub_user_class = Class.new(@user_class)
    sub_user_class.ldap_mapping :dn_attribute => "uid"
    user = sub_user_class.new(:uid => "XXX", :sn => "ZZZ")
    assert_equal("XXX", user.uid)
    assert_nil(user.sn)

    sub_user_class.attr_protected :cn
    user = sub_user_class.new(:uid => "XXX", :sn => "ZZZ", :cn => "Common Name")
    assert_equal("XXX", user.uid)
    assert_nil(user.sn)
    assert_nil(user.cn)

    user = @user_class.new(:uid => "XXX", :sn => "ZZZ", :cn => "Common Name")
    assert_equal("XXX", user.uid)
    assert_nil(user.sn)
    assert_equal("Common Name", user.cn)
  end
end
