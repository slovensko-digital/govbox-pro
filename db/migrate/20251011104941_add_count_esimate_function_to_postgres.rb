class AddCountEsimateFunctionToPostgres < ActiveRecord::Migration[7.1]
  def up
    # https://wiki.postgresql.org/wiki/Count_estimate
    ApplicationRecord.connection.execute <<-SQL
        CREATE OR REPLACE FUNCTION count_estimate(query text)
        RETURNS integer
        LANGUAGE plpgsql AS $$
        DECLARE
          plan jsonb;
        BEGIN
          EXECUTE FORMAT('EXPLAIN (FORMAT JSON) %s', query) INTO plan;
          RETURN (plan->0->'Plan'->>'Plan Rows')::integer;
        END;
        $$;
    SQL
  end

  def down
    ApplicationRecord.connection.execute <<-SQL
      DROP FUNCTION IF EXISTS count_estimate(text);
    SQL
  end
end
