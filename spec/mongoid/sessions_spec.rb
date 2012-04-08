require "spec_helper"

describe Mongoid::Sessions do

  describe ".clear_persistence_options" do

    context "when options exist on the current thread" do

      before do
        Band.with(safe: true)
      end

      let!(:cleared) do
        Band.clear_persistence_options
      end

      it "remove the options from the current thread" do
        Band.persistence_options.should be_nil
      end

      it "returns true" do
        cleared.should be_true
      end
    end

    context "when options do not exist on the current thread" do

      it "returns true" do
        Band.clear_persistence_options.should be_true
      end
    end
  end

  describe "#collection" do

    let(:config) do
      { default: { hosts: [ "localhost:27017" ], database: database_id }}
    end

    let(:session) do
      Mongoid::Sessions::Factory.default
    end

    before do
      Mongoid::Config.sessions = config
      Mongoid::Threaded.sessions[:default] = session
    end

    context "when overriding the default with store_in" do

      before do
        Band.store_in(collection: "artists")
      end

      after do
        Band.storage_options = nil
        Band.send(:remove_instance_variable, :@collection_name)
      end

      let(:band) do
        Band.new
      end

      it "returns the collection for the model" do
        band.collection.should be_a(Moped::Collection)
      end

      it "sets the correct collection name" do
        band.collection.name.should eq(:artists)
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          Band.collection.should be_a(Moped::Collection)
        end

        it "sets the correct collection name" do
          Band.collection.name.should eq(:artists)
        end
      end

      context "when safety options exist" do

        context "when the options are from the current thread" do

          before do
            Band.with(safe: { w: 3 })
          end

          it "clears the options from the current thread" do
            Band.collection
            Band.persistence_options.should be_nil
          end

          it "returns the collection" do
            Band.collection.should be_a(Moped::Collection)
          end
        end
      end
    end

    context "when not overriding the default" do

      after do
        Band.send(:remove_instance_variable, :@collection_name)
      end

      let(:band) do
        Band.new
      end

      it "returns the collection for the model" do
        band.collection.should be_a(Moped::Collection)
      end

      it "sets the correct collection name" do
        band.collection.name.should eq(:bands)
      end

      context "when accessing from the class level" do

        it "returns the collection for the model" do
          Band.collection.should be_a(Moped::Collection)
        end

        it "sets the correct collection name" do
          Band.collection.name.should eq(:bands)
        end
      end
    end
  end

  describe "#collection_name" do

    context "when overriding the default with store_in" do

      before do
        Band.store_in(collection: "artists")
      end

      after do
        Band.storage_options = nil
        Band.send(:remove_instance_variable, :@collection_name)
      end

      let(:band) do
        Band.new
      end

      it "returns the overridden value" do
        band.collection_name.should eq(:artists)
      end

      context "when accessing from the class level" do

        it "returns the overridden value" do
          Band.collection_name.should eq(:artists)
        end
      end
    end

    context "when not overriding the default" do

      let(:band) do
        Band.new
      end

      it "returns the pluralized model name" do
        band.collection_name.should eq(:bands)
      end

      context "when accessing from the class level" do

        it "returns the pluralized model name" do
          Band.collection_name.should eq(:bands)
        end
      end
    end

    context "when the model is a subclass" do

      let(:firefox) do
        Firefox.new
      end

      it "returns the root class pluralized model name" do
        firefox.collection_name.should eq(:canvases)
      end

      context "when accessing from the class level" do

        it "returns the root class pluralized model name" do
          Firefox.collection_name.should eq(:canvases)
        end
      end
    end
  end

  describe "#mongo_session" do

    context "when overriding the default with store_in" do

      let(:config) do
        {
          default: {
            hosts: [ "localhost:27017" ], database: database_id
          },
          secondary: {
            hosts: [ "localhost:27017" ], database: database_id
          }
        }
      end

      let(:session) do
        Mongoid::Sessions::Factory.create(:secondary)
      end

      before do
        Mongoid::Config.sessions = config
        Mongoid::Threaded.sessions[:secondary] = session
        Band.store_in(session: "secondary")
      end

      after do
        Band.storage_options = nil
      end

      let(:band) do
        Band.new
      end

      it "returns the overridden session" do
        band.mongo_session.should eq(session)
      end

      context "when accessing from the class level" do

        it "returns the overridden session" do
          Band.mongo_session.should eq(session)
        end
      end
    end

    context "when no default is overridden" do

      context "when no options are provided" do

        let(:config) do
          { default: { hosts: [ "localhost:27017" ], database: database_id }}
        end

        let(:session) do
          Mongoid::Sessions::Factory.default
        end

        before do
          Mongoid::Config.sessions = config
          Mongoid::Threaded.sessions[:default] = session
        end

        let(:band) do
          Band.new
        end

        it "returns the default session" do
          band.mongo_session.should eq(session)
        end

        context "when accessing from the class level" do

          it "returns the default session" do
            Band.mongo_session.should eq(session)
          end
        end
      end

      context "when options are provided" do

        let(:config) do
          {
            default: {
              database: database_id,
              hosts: [ "localhost:27017" ],
              options: {
                consistency: :strong
              }
            }
          }
        end

        let(:session) do
          Mongoid::Sessions::Factory.default
        end

        before do
          Mongoid::Config.sessions = config
          Mongoid::Threaded.sessions[:default] = session
        end

        let(:band) do
          Band.new
        end

        it "returns the default session" do
          band.mongo_session.should eq(session)
        end

        it "sets the options" do
          band.mongo_session.options[:consistency].should eq(:strong)
        end

        context "when accessing from the class level" do

          it "returns the default session" do
            Band.mongo_session.should eq(session)
          end
        end
      end
    end
  end

  describe ".persistence_options" do

    context "when options exist on the current thread" do

      before do
        Band.with(safe: { w: 2 })
      end

      after do
        Band.clear_persistence_options
      end

      it "returns the options" do
        Band.persistence_options.should eq(safe: { w: 2 })
      end
    end

    context "when there are no options on the current thread" do

      it "returns nil" do
        Band.persistence_options.should be_nil
      end
    end
  end

  describe ".store_in" do

    context "when provided a non hash" do

      it "raises an error" do
        expect {
          Band.store_in :artists
        }.to raise_error(Mongoid::Errors::InvalidStorageOptions)
      end
    end

    context "when provided a hash" do

      context "when the hash is not valid" do

        it "raises an error" do
          expect {
            Band.store_in coll: "artists"
          }.to raise_error(Mongoid::Errors::InvalidStorageOptions)
        end
      end
    end
  end

  describe ".with" do

    context "when sending operations to a different database" do

      after do
        Band.with(database: "mongoid_test_alt").delete_all
      end

      describe ".create" do

        let!(:band) do
          Band.with(database: "mongoid_test_alt").create
        end

        it "does not persist to the default database" do
          expect {
            Band.find(band.id)
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        let(:from_db) do
          Band.with(database: "mongoid_test_alt").find(band.id)
        end

        it "persists to the specified database" do
          from_db.should eq(band)
        end

        it "persists the correct number of documents" do
          Band.with(database: "mongoid_test_alt").count.should eq(1)
        end
      end
    end

    context "when sending operations to a different collection" do

      after do
        Band.with(collection: "artists").delete_all
      end

      describe ".create" do

        let!(:band) do
          Band.with(collection: "artists").create
        end

        it "does not persist to the default database" do
          expect {
            Band.find(band.id)
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        let(:from_db) do
          Band.with(collection: "artists").find(band.id)
        end

        it "persists to the specified database" do
          from_db.should eq(band)
        end

        it "persists the correct number of documents" do
          Band.with(collection: "artists").count.should eq(1)
        end
      end
    end

    context "when sending operations to a different session" do

      let(:config) do
        {
          default: {
            database: database_id,
            hosts: [ "localhost:27017" ],
            options: {
              consistency: :strong
            }
          },
          zwei: {
            database: database_id,
            hosts: [ "localhost:27017" ],
            options: {
              consistency: :strong
            }
          }
        }
      end

      let(:session) do
        Mongoid::Sessions::Factory.default
      end

      before do
        Mongoid::Config.sessions = config
        Mongoid::Threaded.sessions[:default] = session
      end

      describe ".create" do

        let!(:band) do
          Band.with(session: "zwei").create
        end

        let(:from_db) do
          Band.with(session: "zwei").find(band.id)
        end

        it "persists to the specified database" do
          from_db.should eq(band)
        end
      end
    end

    context "when sending operations with safe mode" do

      describe ".create" do

        before do
          Person.with(safe: true).create(ssn: "432-97-1111")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              Person.with(safe: true).create(ssn: "432-97-1111")
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end

        context "when using safe: false" do

          it "ignores mongodb error" do
            Person.with(safe: false).create(ssn: "432-97-1111").should be_true
          end
        end
      end

      describe ".create!" do

        before do
          Person.with(safe: true).create!(ssn: "432-97-1112")
        end

        context "when no error occurs" do

          it "inserts the document" do
            Person.count.should eq(1)
          end
        end

        context "when a mongodb error occurs" do

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              Person.with(safe: true).create!(ssn: "432-97-1112")
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          it "raises the validation error" do
            expect {
              Account.with(safe: true).create!(name: "this name is way too long")
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end

      describe ".save" do

        before do
          Person.with(safe: true).create(ssn: "432-97-1113")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1113")
          end

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              person.with(safe: true).save
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end
      end

      describe ".save!" do

        before do
          Person.with(safe: true).create!(ssn: "432-97-1114")
        end

        context "when a mongodb error occurs" do

          let(:person) do
            Person.new(ssn: "432-97-1114")
          end

          before do
            Person.create_indexes
          end

          it "bubbles up to the caller" do
            expect {
              person.with(safe: true).save!
            }.to raise_error(Moped::Errors::OperationFailure)
          end
        end

        context "when a validation error occurs" do

          let(:account) do
            Account.new(name: "this name is way too long")
          end

          it "raises the validation error" do
            expect {
              account.with(safe: true).save!
            }.to raise_error(Mongoid::Errors::Validations)
          end
        end
      end
    end
  end
end
