require 'spec_helper'

describe FlexiModel::ArPersistence do
  class PcUser
    include FlexiModel
    include Paperclip::Glue

    _string :name, :avatar_file_name, :avatar_content_type
    _integer :avatar_file_size
    _datetime :avatar_updated_at

    has_attached_file :avatar,
                      :path            => "system/:attachment/:id/:style/:filename",
                      :url             => "/system/:attachment/:id/:style/:filename",

                      :styles          => {
                          :original => ['800x800>', :jpg],
                          :small    => ['100x100#', :jpg],
                          :medium   => ['250x250', :jpg],
                          :large    => ['500x500>', :jpg]
                      },
                      :convert_options => { :all => '-background white -flatten +matte' }
    _attachment :avatar
  end

  before {
    Paperclip.options[:log] = false
  }

  describe PcUser do
    let(:image_file) { File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'image.png') }
    let(:image2_file) { File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'image2.png') }

    it 'should create user with attachment without any error' do
      lambda {
        PcUser.create(name: 'hasan', avatar: File.new(image_file))
      }.should_not raise_error
    end

    it 'should have attachment' do
      user = PcUser.create(name: 'hasan', avatar: File.new(image_file))
      inst = user.reload

      inst.name.should == 'hasan'
      inst.avatar.should be
    end

    it 'should update attachment' do
      user = PcUser.create(name: 'hasan', avatar: File.new(image_file))
      inst = user.reload

      inst.update_attribute :avatar, File.new(image2_file)
      inst2 = inst.reload

      inst2.avatar_file_name.should == 'image2.png'
      inst2.avatar.should be
    end

    it 'should create file in system folder' do
      user        = PcUser.create(name: 'hasan', avatar: File.new(image_file))
      system_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'system', 'avatars', user.id.to_s)

      File.exist?(system_path).should be
      File.exist?(File.join(system_path, 'large', 'image.jpg')).should be
      File.exist?(File.join(system_path, 'small', 'image.jpg')).should be
      File.exist?(File.join(system_path, 'medium', 'image.jpg')).should be
      File.exist?(File.join(system_path, 'original', 'image.jpg')).should be
    end

    it 'should destroy attachment' do
      user = PcUser.create(name: 'hasan', avatar: File.new(image_file))
      user.destroy
      system_path = File.join(File.dirname(__FILE__), '..', '..', '..', 'system', 'avatars', user.id.to_s)

      File.exist?(system_path).should be_false
    end

    it 'should return attachment url' do
      user = PcUser.create(name: 'hasan', avatar: File.new(image_file))

      user.avatar.url(:small).should match /^\/system\/avatars\/#{user.id}\/small\/image\.jpg/
    end
  end
end