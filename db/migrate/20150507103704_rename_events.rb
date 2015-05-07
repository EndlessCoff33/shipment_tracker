class RenameEvents < ActiveRecord::Migration

  def conversion
    {
      'CircleCi' => 'CircleCiEvent',
      'Deploy'   => 'DeployEvent',
      'Jenkins'  => 'JenkinsEvent',
    }
  end

  def up
    conversion.each do |original_type, new_type|
      Event.where(type: original_type).update_all(type: new_type)
    end
  end

  def down
    conversion.each do |original_type, new_type|
      Event.where(type: new_type).update_all(type: original_type)
    end
  end
end
