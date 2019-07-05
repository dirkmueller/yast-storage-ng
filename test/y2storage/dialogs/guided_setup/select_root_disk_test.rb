#!/usr/bin/env rspec
# Copyright (c) [2017-2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../../spec_helper.rb"
require_relative "#{TEST_PATH}/support/guided_setup_context"

describe Y2Storage::Dialogs::GuidedSetup::SelectRootDisk do
  include_context "guided setup requirements"

  subject { described_class.new(guided_setup) }

  before do
    settings.candidate_devices = candidate_disks
    settings.delete_resize_configurable = partition_actions
  end

  let(:partition_actions) { true }

  describe "#skip?" do
    context "when there is only one candidate disk" do
      let(:candidate_disks) { ["/dev/sda"] }

      context "and the candidate disk has no partitions" do
        let(:partitions) { { "/dev/sda" => [] } }

        it "returns true" do
          expect(subject.skip?).to be(true)
        end
      end

      context "and the candidate disk has partitions" do
        let(:partitions) { { "/dev/sda" => ["sda1"] } }

        context "and the partition actions are configurable" do
          let(:partition_actions) { true }

          it "returns false" do
            expect(subject.skip?).to be(false)
          end
        end

        context "and the partition actions are not configurable" do
          let(:partition_actions) { false }

          it "returns true" do
            expect(subject.skip?).to be(true)
          end
        end
      end
    end

    context "where there are several candidate disks" do
      let(:candidate_disks) { ["/dev/sda", "/dev/sdb"] }

      it "returns false" do
        expect(subject.skip?).to be(false)
      end
    end
  end

  describe "#before_skip" do
    let(:all_disks) { ["/dev/sda", "/dev/sdb"] }
    let(:candidate_disks) { all_disks }

    it "sets the first candidate disk as root disk" do
      subject.before_skip

      expect(settings.root_device).to eq("/dev/sda")
    end
  end

  describe "#next_handler" do
    let(:all_disks) { ["/dev/sda", "/dev/sdb"] }
    let(:candidate_disks) { all_disks }

    let(:windows_partitions) { [partition_double("sda1")] }
    let(:linux_partitions) { [partition_double("sda2")] }

    let(:partitions) do
      { "/dev/sda" => [partition_double("sda1"), partition_double("sda2"), partition_double("sda3")] }
    end

    before do
      allow(Y2Storage::Dialogs::GuidedSetup::Widgets::RootDiskSelector)
        .to receive(:new).and_return(root_disk_widget)

      allow(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
        .to receive(:new).and_return(actions_widget)
    end

    let(:root_disk_widget) do
      instance_double(Y2Storage::Dialogs::GuidedSetup::Widgets::RootDiskSelector, store: true)
    end

    let(:actions_widget) do
      instance_double(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions, store: true)
    end

    it "stores all widgets" do
      expect(root_disk_widget).to receive(:store)
      expect(actions_widget).to receive(:store)

      subject.next_handler
    end
  end

  describe "#run" do
    before do
      allow(subject).to receive(:next_handler)
    end

    let(:all_disks) { ["/dev/sda", "/dev/sdb"] }
    let(:candidate_disks) { all_disks }

    it "contains a widget to select the root disk" do
      expect(Y2Storage::Dialogs::GuidedSetup::Widgets::RootDiskSelector)
        .to receive(:new).and_call_original

      subject.run
    end

    context "when the partiton actions (delete and resize) are not configurable" do
      let(:partition_actions) { false }

      let(:windows_partitions) { [partition_double("sda1")] }
      let(:linux_partitions) { [partition_double("sda2")] }

      let(:partitions) do
        { "/dev/sda" => [partition_double("sda1"), partition_double("sda2"), partition_double("sda3")] }
      end

      it "does not contain a widget to configure the partition actions" do
        expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions).to_not receive(:new)

        subject.run
      end
    end

    context "when the partiton actions (delete and resize) are configurable" do
      let(:partition_actions) { true }

      context "and there are Windows partitions" do
        let(:windows_partitions) { [partition_double("sda1")] }

        it "contains a widget for the Windows partition actions" do
          expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
            .to receive(:new).with(anything, anything, hash_including(windows: true)).and_call_original

          subject.run
        end
      end

      context "and there are no Windows partitions" do
        let(:windows_partitions) { [] }

        it "does not contain a widget for the Windows partition actions" do
          expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
            .to receive(:new).with(anything, anything, hash_including(windows: false)).and_call_original

          subject.run
        end
      end

      context "and there are Linux partitions" do
        let(:linux_partitions) { [partition_double("sda1")] }

        it "contains a widget for the Linux partition actions" do
          expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
            .to receive(:new).with(anything, anything, hash_including(linux: true)).and_call_original

          subject.run
        end
      end

      context "and there are no Linux partitions" do
        let(:linux_partitions) { [] }

        it "does not enable a widget for the Linux partition actions" do
          expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
            .to receive(:new).with(anything, anything, hash_including(linux: false)).and_call_original

          subject.run
        end
      end

      context "and there are other partitions" do
        let(:partitions) { { "/dev/sda" => [partition_double("sda1")] } }

        it "contains a widget for other partitions actions" do
          expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
            .to receive(:new).with(anything, anything, hash_including(other: true)).and_call_original

          subject.run
        end
      end

      context "and there are no other partitions" do
        let(:linux_partitions) { [partition_double("sda1")] }

        let(:partitions) { { "/dev/sda" => [partition_double("sda1")] } }

        it "does not enable a widget for other partitions actions" do
          expect(Y2Storage::Dialogs::GuidedSetup::Widgets::PartitionActions)
            .to receive(:new).with(anything, anything, hash_including(other: false)).and_call_original

          subject.run
        end
      end
    end
  end
end
