require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset links to the admin host in the current locale" do
    user = users(:elshohail_owner)

    mail = I18n.with_locale(:en) { PasswordsMailer.reset(user).message }

    assert_equal [ user.email_address ], mail.to
    assert_equal I18n.t("passwords_mailer.reset.subject", locale: :en), mail.subject
    assert_match %r{http://app\.example\.com/passwords/[^/\s]+/edit}, mail.text_part.body.to_s
  end
end
