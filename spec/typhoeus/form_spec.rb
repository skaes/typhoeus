require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Typhoeus::Form do
  describe "#process!" do
    it "should generate a valid form object" do
      form = Typhoeus::Form.new({
        :name => "John Smith",
        :age => "29"
      })
      expect(form).to receive(:formadd_param).with("name", "John+Smith")
      expect(form).to receive(:formadd_param).with("age", "29")
      form.process!
    end

    it "should handle params that are a hash" do
      form = Typhoeus::Form.new({
        :attributes => {
          :eyes => "brown",
          :hair => "green",
          :teeth => "white"
        },
        :name => "John Smith",
        :age => "29"
      })
      expect(form).to receive(:formadd_param).with("attributes%5Beyes%5D", "brown")
      expect(form).to receive(:formadd_param).with("attributes%5Bhair%5D", "green")
      expect(form).to receive(:formadd_param).with("attributes%5Bteeth%5D", "white")
      expect(form).to receive(:formadd_param).with("name", "John+Smith")
      expect(form).to receive(:formadd_param).with("age", "29")
      form.process!
    end

    it "should params that have mutliple values" do
      form = Typhoeus::Form.new({
        :colors => ["brown", "green", "white"],
        :name => "John Smith",
        :age => "29"
      })
      expect(form).to receive(:formadd_param).with("colors", "brown")
      expect(form).to receive(:formadd_param).with("colors", "green")
      expect(form).to receive(:formadd_param).with("colors", "white")
      expect(form).to receive(:formadd_param).with("name", "John+Smith")
      expect(form).to receive(:formadd_param).with("age", "29")
      form.process!
    end

    context "when a File object is a param" do
      it "should handle one file" do
        form = Typhoeus::Form.new(
          :file => File.open(File.expand_path(File.dirname(__FILE__) + "/../fixtures/placeholder.txt"), "r")
        )
        expect(form).to receive(:formadd_file).with("file", "placeholder.txt", "text/plain", anything)
        form.process!
      end

      it "should handle more than one file" do
        form = Typhoeus::Form.new(
          :text_file => File.open(File.expand_path(File.dirname(__FILE__) + "/../fixtures/placeholder.txt"), "r"),
          :gif_file => File.open(File.expand_path(File.dirname(__FILE__) + "/../fixtures/placeholder.gif"), "r")
        )
        expect(form).to receive(:formadd_file).with("gif_file", "placeholder.gif", "image/gif", anything)
        expect(form).to receive(:formadd_file).with("text_file", "placeholder.txt", "text/plain", anything)
        form.process!
      end

      it "should handle tempfiles (file subclasses)" do
        tempfile = Tempfile.new('placeholder_temp')
        form = Typhoeus::Form.new(
          :file => tempfile
        )
        expect(form).to receive(:formadd_file).with("file", File.basename(tempfile.path), "application/octet-stream", anything)
        form.process!
      end

      it "should default to 'application/octet-stream' if no content type can be determined" do
        skip
        form = Typhoeus::Form.new(
          :file => File.open(File.expand_path(File.dirname(__FILE__) + "/../fixtures/placeholder.txt"), "r")
        )
        expect(form).to receive(:formadd_file).with("file", "placeholder.ukn", "application/octet-stream", anything)
        form.process!
      end
    end
  end

  describe "#to_s" do
    it "should generate a valid query string" do
      form = Typhoeus::Form.new({
        :name => "John Smith",
        :age => "29"
      })
      expect(form.to_s).to eq("age=29&name=John+Smith")
    end

    it "should handle params that are a hash" do
      form = Typhoeus::Form.new({
        :attributes => {
          :eyes => "brown",
          :hair => "green",
          :teeth => "white"
        },
        :name => "John Smith",
        :age => "29"
      })
      expect(form.to_s).to eq("age=29&attributes%5Beyes%5D=brown&attributes%5Bhair%5D=green&attributes%5Bteeth%5D=white&name=John+Smith")
    end

    it "should params that have multiple values" do
      form = Typhoeus::Form.new({
        :colors => ["brown", "green", "white"],
        :name => "John Smith",
        :age => "29"
      })
      expect(form.to_s).to eq("age=29&colors=brown&colors=green&colors=white&name=John+Smith")
    end
  end
end
