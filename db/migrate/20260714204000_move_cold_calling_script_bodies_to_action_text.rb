class MoveColdCallingScriptBodiesToActionText < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
      SELECT 'body', body, 'ColdCallingScript', id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM cold_calling_scripts
      WHERE body IS NOT NULL AND body <> ''
    SQL

    remove_column :cold_calling_scripts, :body, :text
  end

  def down
    add_column :cold_calling_scripts, :body, :text

    execute <<~SQL.squish
      UPDATE cold_calling_scripts
      SET body = action_text_rich_texts.body
      FROM action_text_rich_texts
      WHERE action_text_rich_texts.record_type = 'ColdCallingScript'
        AND action_text_rich_texts.record_id = cold_calling_scripts.id
        AND action_text_rich_texts.name = 'body'
    SQL

    execute <<~SQL.squish
      DELETE FROM action_text_rich_texts
      WHERE record_type = 'ColdCallingScript' AND name = 'body'
    SQL

    change_column_null :cold_calling_scripts, :body, false
  end
end
