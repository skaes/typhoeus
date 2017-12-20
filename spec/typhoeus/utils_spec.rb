require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

require 'active_support/all'

describe Typhoeus::Utils do
  # Taken from Rack 1.2.1
  describe "#escape" do
    it "should escape correctly" do
      Typhoeus::Utils.escape("fo<o>bar").should == "fo%3Co%3Ebar"
      Typhoeus::Utils.escape("a space").should == "a+space"
      Typhoeus::Utils.escape("q1!2\"'w$5&7/z8)?\\").
        should == "q1%212%22%27w%245%267%2Fz8%29%3F%5C"
    end

    let(:text_to_escape) do
<<-TXT
Hallo Frau 张,\n\ngute Nachrichten: Sie wurden für den XING TalentpoolManager freigeschaltet.\n\nLegen Sie ganz einfach los, indem Sie sich hier mit Ihren pers
önlichen XING Zugangsdaten einloggen:\n\nhttps://www.xing.com/xtm\n\nGerne unterstützen wir Sie beim Start mit dem TalentpoolManager. Sie sind herzlich eingeladen, an einem kostenfreien Online-Seminar zur E
inführung in die Hauptbereiche und die wichtigsten Funktionen des TalentpoolManagers teilzunehmen.\nEine Übersicht über unsere Seminare und deren Termine finden Sie auf unserer XING E-Recruiting-Website: ht
tps://community.xing.com/s/login/?language=de&amp;startURL=%2Fs%2Frecruiting-tipps%3Ftabset-24bad%3D1&amp;ec=302\n\nHaben Sie noch Fragen?\n\nDie Antworten auf die häufigsten Fragen finden Sie im Bereich &q
uot;Fragen &amp; Antworten&quot; direkt im TalentpoolManager.\nSie können uns auch telefonisch unter +49 40 419 131-778 kontaktieren oder per E-Mail an xtp@xing.com.\n\nWir wünschen Ihnen nun viel Erfolg mi
t dem TalentpoolManager!\n\nMit freundlichen Grüßen\nIhr XING E-Recruiting-Team\n\n\nTipp: Für einen schnellen Zugang zum TalentpoolManager empfehlen wir Ihnen, sich den Link https://www.xing.com/xtm als Le
sezeichen im Browser abzuspeichern.\n 
TXT
    end

    let(:escaped_string) do
<<-STRING.strip
Hallo+Frau+%E5%BC%A0%2C%0A%0Agute+Nachrichten%3A+Sie+wurden+f%C3%BCr+den+XING+TalentpoolManager+freigeschaltet.%0A%0ALegen+Sie+ganz+einfach+los%2C+indem+Sie+sich+hier+mit+Ihren+pers%0A%C3%B6nlichen+XING+Zugangsdaten+einloggen%3A%0A%0Ahttps%3A%2F%2Fwww.xing.com%2Fxtm%0A%0AGerne+unterst%C3%BCtzen+wir+Sie+beim+Start+mit+dem+TalentpoolManager.+Sie+sind+herzlich+eingeladen%2C+an+einem+kostenfreien+Online-Seminar+zur+E%0Ainf%C3%BChrung+in+die+Hauptbereiche+und+die+wichtigsten+Funktionen+des+TalentpoolManagers+teilzunehmen.%0AEine+%C3%9Cbersicht+%C3%BCber+unsere+Seminare+und+deren+Termine+finden+Sie+auf+unserer+XING+E-Recruiting-Website%3A+ht%0Atps%3A%2F%2Fcommunity.xing.com%2Fs%2Flogin%2F%3Flanguage%3Dde%26amp%3BstartURL%3D%252Fs%252Frecruiting-tipps%253Ftabset-24bad%253D1%26amp%3Bec%3D302%0A%0AHaben+Sie+noch+Fragen%3F%0A%0ADie+Antworten+auf+die+h%C3%A4ufigsten+Fragen+finden+Sie+im+Bereich+%26q%0Auot%3BFragen+%26amp%3B+Antworten%26quot%3B+direkt+im+TalentpoolManager.%0ASie+k%C3%B6nnen+uns+auch+telefonisch+unter+%2B49+40+419+131-778+kontaktieren+oder+per+E-Mail+an+xtp%40xing.com.%0A%0AWir+w%C3%BCnschen+Ihnen+nun+viel+Erfolg+mi%0At+dem+TalentpoolManager%21%0A%0AMit+freundlichen+Gr%C3%BC%C3%9Fen%0AIhr+XING+E-Recruiting-Team%0A%0A%0ATipp%3A+F%C3%BCr+einen+schnellen+Zugang+zum+TalentpoolManager+empfehlen+wir+Ihnen%2C+sich+den+Link+https%3A%2F%2Fwww.xing.com%2Fxtm+als+Le%0Asezeichen+im+Browser+abzuspeichern.%0A+%0A
STRING
    end

    it "should convert objects that override #to_s into Strings" do
      Typhoeus::Utils.escape(ActiveSupport::SafeBuffer.new(text_to_escape)).should == escaped_string
    end

    it "should escape correctly for multibyte characters" do
      matz_name = "\xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8".unpack("a*")[0] # Matsumoto
      matz_name.force_encoding("UTF-8") if matz_name.respond_to? :force_encoding
      Typhoeus::Utils.escape(matz_name).should == '%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8'
      matz_name_sep = "\xE3\x81\xBE\xE3\x81\xA4 \xE3\x82\x82\xE3\x81\xA8".unpack("a*")[0] # Matsu moto
      matz_name_sep.force_encoding("UTF-8") if matz_name_sep.respond_to? :force_encoding
      Typhoeus::Utils.escape(matz_name_sep).should == '%E3%81%BE%E3%81%A4+%E3%82%82%E3%81%A8'
    end
  end
end
