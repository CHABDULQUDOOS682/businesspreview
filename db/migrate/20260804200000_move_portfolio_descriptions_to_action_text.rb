# frozen_string_literal: true

class MovePortfolioDescriptionsToActionText < ActiveRecord::Migration[8.0]
  def up
    say_with_time "copy portfolio_items.description into action_text_rich_texts" do
      execute <<~SQL.squish
        INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
        SELECT
          'description',
          description,
          'PortfolioItem',
          id,
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        FROM portfolio_items
        WHERE description IS NOT NULL
          AND BTRIM(description) <> ''
          AND NOT EXISTS (
            SELECT 1
            FROM action_text_rich_texts
            WHERE action_text_rich_texts.record_type = 'PortfolioItem'
              AND action_text_rich_texts.record_id = portfolio_items.id
              AND action_text_rich_texts.name = 'description'
          )
      SQL
    end

    say_with_time "normalize portfolio metrics to subscription plan names" do
      execute <<~SQL.squish
        UPDATE portfolio_items
        SET metric = CASE
          WHEN metric ILIKE '%appointment%' OR metric ILIKE '%booking%' THEN 'Business Pro'
          WHEN metric ILIKE '%hosting%' OR metric ILIKE '%search%' THEN 'Essential'
          WHEN metric IS NULL OR BTRIM(metric) = '' THEN NULL
          ELSE 'Growth'
        END
        WHERE metric IS NULL
           OR metric NOT IN ('Essential', 'Growth', 'Business Pro')
      SQL
    end

    remove_column :portfolio_items, :description, :text
  end

  def down
    add_column :portfolio_items, :description, :text

    say_with_time "restore portfolio_items.description from action_text_rich_texts" do
      execute <<~SQL.squish
        UPDATE portfolio_items
        SET description = action_text_rich_texts.body
        FROM action_text_rich_texts
        WHERE action_text_rich_texts.record_type = 'PortfolioItem'
          AND action_text_rich_texts.record_id = portfolio_items.id
          AND action_text_rich_texts.name = 'description'
      SQL
    end

    execute <<~SQL.squish
      DELETE FROM action_text_rich_texts
      WHERE record_type = 'PortfolioItem' AND name = 'description'
    SQL
  end
end
