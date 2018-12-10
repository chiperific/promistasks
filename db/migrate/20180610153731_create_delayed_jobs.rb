class CreateDelayedJobs < ActiveRecord::Migration[5.1]
  def self.up
    create_table :delayed_jobs, force: true do |t|
      t.integer :priority, default: 0, null: false # Allows some jobs to jump to the front of the queue
      t.integer :attempts, default: 0, null: false # Provides for retries, but still fail eventually.
      t.text :handler,                 null: false # YAML-encoded string of the object that will do work
      t.text :last_error                           # reason for last failure (See Note below)
      t.datetime :run_at                           # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      t.datetime :locked_at                        # Set when a client is working on this object
      t.datetime :failed_at                        # Set when all retries have failed (actually, by default, the record is deleted instead)
      t.string :locked_by                          # Who is working on this object (if locked)
      t.string :queue                              # The name of the queue this job is in
      t.timestamps null: true
      t.string    :identifier
      t.string    :record_type
      t.integer   :record_id
      t.string    :handler_class
      t.integer   :progress_current,  null: false, default: 0
      t.integer   :progress_max,      null: false, default: 100
      t.string    :message
      t.string    :error_message
      t.string    :cron
      t.datetime  :completed_at
    end

    add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"
    add_index :delayed_jobs, :identifier
    add_index :delayed_jobs, [:record_type, :record_id]
    add_index :delayed_jobs, :handler_class
    add_index :delayed_jobs, :completed_at
  end

  def self.down
    drop_table :delayed_jobs
  end
end
