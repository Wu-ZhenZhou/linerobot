class CreateReplies < ActiveRecord::Migration[7.0]
  def change
    create_table :replies do |t|
      t.string :channel_id
      t.string :text

      t.timestamps
    end
  end
end
