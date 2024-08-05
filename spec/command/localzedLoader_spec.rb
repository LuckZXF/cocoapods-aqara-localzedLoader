require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Localzedloader do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ localzedLoader }).should.be.instance_of Command::Localzedloader
      end
    end
  end
end

