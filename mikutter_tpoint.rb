# -*- coding: utf-8 -*-
require 'mechanize'

Plugin.create(:mikutter_tpoint) do
  #セキュリティ...?なにそれ?
  I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  #アクティビティ
  defactivity 'showtpoint', 'Tポイントプラグイン'

  def getTPoint(user,password)
    agent = Mechanize::new
    agent.user_agent = 'Mozilla/5.0 (Linux; U; Android 2.3.2; ja-jp; SonyEricssonSO-01C Build/3.0.D.2.79) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1'
    agent.get('http://login.yahoo.co.jp/config/login?.lg=jp&.intl=jp&logout=1&.src=www&.done=http://www.yahoo.co.jp')
    #時間を置かないと怒られるゾ
    sleep 2
    agent.get('https://login.yahoo.co.jp/config/login?.src=www&.done=http://www.yahoo.co.jp')
    agent.page.form_with(name: 'login_form') do |form|
      form.field_with(name: 'login').value = user
      form.field_with(name: 'passwd').value = password
      agent.page.body =~ /\("\.albatross"\)\[0\]\.value = "(.*)"/
      form.field_with(name: '.albatross').value = $1
      form.click_button
    end
    #時間を置かないと怒られるゾ
    sleep 2
    agent.get('http://points.yahoo.co.jp/')
    return agent.page.at('.ptsPoint').text
  end

  settings("Tポイント") do
    input("ユーザー名",:tpoint_username)
    inputpass("パスワード",:tpoint_password)
  end

  command(:get_tpoint,
  name: 'Tポイント残高を取得',
  condition: lambda{ |opt| true },
  visible: true,
  icon: File.dirname(__FILE__) + "/TPoint.png",
  role: :window) do |opt|
    if UserConfig[:tpoint_username].empty? || UserConfig[:tpoint_password].empty? then
      diag = REGZADialog.new
      diag.showregza
      activity :showtpoint, "設定からユーザー名とパスワードを設定して、どうぞ"
    else
      Thread.new {
        begin
          mesg = "Tポイントの残高は" + getTPoint(UserConfig[:tpoint_username],UserConfig[:tpoint_password]) + "ポイントです。"
          activity :showtpoint, mesg
        rescue => ex
          activity :showtpoint, ex.message
        end
      }
    end
  end

  #レグザダイアログ
  class REGZADialog
    attr_accessor :window
    def showregza
      @window = Gtk::Window.new
      @window.title = "TimeOn サービス紹介"
      @close_btn = Gtk::Button.new("閉じる")
      @close_btn.signal_connect("clicked") do
        @window.destroy
      end
      @show_btn = Gtk::Button.new("サービスを開く")
      @show_btn.signal_connect("clicked") do
        Gtk.openurl("http://www.toshiba.co.jp/regza/campaign/tpoint/index_j.html")
      end
      @gtkimage = Gtk::Image.new(File.dirname(__FILE__) + "/REGZA.png")
      #pack
      hbox = Gtk::HBox.new(true, 0)
      hbox.pack_start(@close_btn, true, true, 5)
      hbox.pack_start(@show_btn, true, true, 5)
      vbox = Gtk::VBox.new(false, 0)
      vbox.pack_start(@gtkimage, false, false, 5)
      vbox.pack_start(hbox, false, false, 5)
      @window.add(vbox)
      @window.show_all
    end
  end

  #未ログインだと宣伝を出す
  on_boot do |service|
    if UserConfig[:tpoint_username].empty? || UserConfig[:tpoint_password].empty? then
      diag = REGZADialog.new
      diag.showregza
    end
  end

end
