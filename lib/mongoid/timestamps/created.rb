# encoding: utf-8
module Mongoid #:nodoc:
  module Timestamps
    # This module handles the behaviour for setting up document created at
    # timestamp.
    module Created
      extend ActiveSupport::Concern

      included do
        field :created_at, type: Time
        set_callback :create, :before, :set_created_at, if: :timestamping?
      end

      # Update the created_at field on the Document to the current time. This is
      # only called on create.
      #
      # @example Set the created at time.
      #   person.set_created_at
      def set_created_at
        if !created_at
          time = Time.now.utc
          self.updated_at = time if is_a?(Updated)
          self.created_at = time
        end
      end
    end
  end
end
