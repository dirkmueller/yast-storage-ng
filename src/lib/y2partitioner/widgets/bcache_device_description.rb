# encoding: utf-8

# Copyright (c) [2018] SUSE LLC
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

require "y2partitioner/widgets/disk_device_description"

module Y2Partitioner
  module Widgets
    # Richtext filled with the description of a bcache device
    #
    # The bcache device is given during initialization (see {BlkDeviceDescription}).
    class BcacheDeviceDescription < DiskDeviceDescription
      def initialize(*args)
        super
        textdomain "storage"
      end

      # @see #disk_device_description
      # @see #bcache_description
      #
      # @return [String]
      def device_description
        super + bcache_description
      end

      # Specialized description for devices at backend of bcache
      # @return [String]
      def bcache_description
        output = Yast::HTML.Heading(_("Bcache Devices:"))
        output << Yast::HTML.List(bcache_attributes)
      end

      # Fields to show in help
      #
      # @return [Array<Symbol>]
      def help_fields
        super + bcache_help_fields
      end

    private

      # Attributes for describing a bcache device
      #
      # @return [Array<String>]
      def bcache_attributes
        [
          format(_("Backing Device: %s"), backing_device),
          format(_("Caching UUID: %s"), uuid),
          format(_("Caching Device: %s"), caching_device),
          format(_("Cache Mode: %s"), cache_mode)
        ]
      end

      def uuid
        device.bcache_cset ? device.bcache_cset.uuid : ""
      end

      def caching_device
        device.bcache_cset ? device.bcache_cset.blk_devices.map(&:name).join(",") : ""
      end

      # Backing device name or an empty string if the device is a flash-only bcache
      #
      # @return [String]
      def backing_device
        return "" if device.flash_only?

        device.backing_device.name
      end

      # Cache mode or an empty string if the device is a flash-only bcache
      #
      # @return [String]
      def cache_mode
        return "" if device.flash_only?

        device.cache_mode.to_human_string
      end

      BCACHE_HELP_FIELDS = [:backing_device, :caching_uuid, :caching_device, :cache_mode].freeze

      # Help fields for a bcache device
      #
      # @return [Array<Symbol>]
      def bcache_help_fields
        BCACHE_HELP_FIELDS.dup
      end
    end
  end
end
