require 'spec_helper'

describe TrogdirChange, type: :unit do
  let(:fixture) { 'create_employee' }
  let(:hash) { JSON.parse(File.read("./spec/fixtures/#{fixture}.json")) }
  subject { TrogdirChange.new(hash) }

  describe '#sync_log_id' do
    it { expect(subject.sync_log_id).to eql '000000000000000000000000'}
  end

  describe '#person_uuid' do
    it { expect(subject.person_uuid).to eql '00000000-0000-0000-0000-000000000000'}
  end

  describe '#preferred_name' do
    it { expect(subject.preferred_name).to eql 'Bob'}
  end

  describe '#first_name' do
    it { expect(subject.first_name).to eql 'Robert'}
  end

  describe '#middle_name' do
    it { expect(subject.middle_name).to eql 'Joseph'}
  end

  describe '#last_name' do
    it { expect(subject.last_name).to eql 'Dole'}
  end

  describe '#old_affiliations' do
    it { expect(subject.old_affiliations).to eql []}
  end

  describe '#new_affiliations' do
    it { expect(subject.new_affiliations).to eql ['employee']}
  end

  describe '#affiliations' do
    it { expect(subject.affiliations).to eql ['employee']}
  end

  describe '#university_email' do
    context 'when creating a person' do
      it { expect(subject.university_email).to eql 'bob.dole@biola.edu' }
    end

    context 'when creating an email' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_email.json')) }

      it { expect(subject.university_email).to eql 'bob.dole@biola.edu' }
    end
  end

  describe '#university_email_exists?' do
    context 'with a university email' do
      it { expect(subject.university_email_exists?).to be true }
    end

    context 'without a university email' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_employee_without_university_email.json')) }

      it { expect(subject.university_email_exists?).to be false }
    end
  end

  describe '#affiliations_changed?' do
    context 'when creating a person with affiliations' do
      it { expect(subject.affiliations_changed?).to be true }
    end

    context 'when creating an id' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_id.json')) }

      it { expect(subject.affiliations_changed?).to be false }
    end
  end

  describe '#affiliation_added?' do
    context 'when creating a person with affiliations' do
      it { expect(subject.affiliation_added?).to be true }
    end

    context 'when creating an id' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_id.json')) }

      it { expect(subject.affiliation_added?).to be false }
    end

    context 'when updating a person but not changing affiliations' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person.json')) }

      it { expect(subject.affiliation_added?).to be false }
    end

    context 'when removing an affiliaton' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person_remove_affiliation.json')) }
      it { expect(subject.affiliation_added?).to be false }
    end
  end

  describe '#university_email_added?' do
    context 'when creating a university email' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_email.json')) }

      it { expect(subject.university_email_added?).to be true }
    end

    context 'when creating a personal email' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_personal_email.json')) }

      it { expect(subject.university_email_added?).to be false }
    end
  end

  describe '#account_info_updated?' do
    context 'when changing name' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person_name.json')) }

      it { expect(subject.account_info_updated?).to be true }
    end

    context 'when changing work_info' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person.json')) }

      it { expect(subject.account_info_updated?).to be true }
    end

    context 'when changing privacy' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person_privacy.json')) }

      it { expect(subject.account_info_updated?).to be true }
    end

    context 'when creating an id' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_id.json')) }

      it { expect(subject.account_info_updated?).to be false }
    end

    context 'when changing partial_ssn' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person_ssn.json')) }

      it { expect(subject.account_info_updated?).to be false }
    end
  end

  describe '#joined_groups' do
    context 'when creating a person' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_employee.json')) }

      it { expect(subject.joined_groups).to eql [] }
    end

    context 'when joining a group' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/join_group.json')) }

      it { expect(subject.joined_groups).to eql ['President'] }
    end
  end

  describe '#left_groups' do
    context 'when creating a person' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/create_employee.json')) }

      it { expect(subject.left_groups).to eql [] }
    end

    context 'when joining a group' do
      let(:hash) { JSON.parse(File.read('./spec/fixtures/leave_group.json')) }

      it { expect(subject.left_groups).to eql ['Congressman'] }
    end
  end
end
