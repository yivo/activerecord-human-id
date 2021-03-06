# encoding: utf-8
# frozen_string_literal: true

module HumanID
  module Transliteration
    class << self
      #
      # HumanID::Transliteration.perform('Well-known English writer')
      #   => 'well-known-english-writer'
      #
      # HumanID::Transliteration.perform('Well-known English writer', normalize: false, downcase: false)
      #   => 'Well-known English writer'
      #
      # HumanID::Transliteration.perform('Пушкин, Александр Сергеевич')
      #   => 'pushkin-aleksandr-sergeevich'
      #
      # HumanID::Transliteration.perform('Пушкин, Александр Сергеевич', normalize: false, downcase: false)
      #   => 'Pushkin, Aleksandr Sergeevich'
      #
      def perform(str, options = {})
        previous_locale = I18n.locale
        I18n.locale     = I18n.default_locale
        separator       = options.fetch(:separator, behaviour.separator)
        downcase        = options.fetch(:downcase, behaviour.perform_downcase?)
        normalize       = options.fetch(:normalize, behaviour.perform_normalization?)

        str = str.join(separator) if str.is_a?(Array)
        str = I18n.transliterate(str)

        str = str.downcase if downcase

        if normalize

          # Replace non-word and non-ASCII characters with hyphens.
          str = str.gsub(/\W/, '-')

          # Strip leading and trailing hyphens.
          str = str.gsub(/(\A-+)|(-+\z)/, '')

          # Collapse hyphens.
          str = str.gsub(/-+/, '-')

        end

        str
      ensure
        I18n.locale = previous_locale
      end


      def valid?(human_id)
        human_id = human_id.to_s if human_id.kind_of?(Symbol)
        human_id.kind_of?(String) && !!(human_id =~ behaviour.validation_regex)
      end

      def validate!(human_id)
        raise MalformedHumanIDError unless valid?(human_id)
        true
      end

      def behaviour
        Behaviour.instance
      end
    end

    class Behaviour
      include Singleton

      attr_accessor :separator, :downcase, :normalize, :validation_regex

      def initialize
        self.separator = '-'
        self.downcase  = true
        self.normalize = true

        # Not starts with hyphen
        # Contains 1 to 255 word characters and hyphens
        # Not ends with hyphen
        # TODO Validation with custom separator
        self.validation_regex = /(?!-)\A[\w-]{1,255}(?<!-)\z/
      end

      def perform_downcase?
        downcase
      end

      def perform_normalization?
        normalize
      end
    end

    class MalformedHumanIDError < StandardError
      def initialize
        super 'Human ID is malformed'
      end
    end
  end

  class << self
    def transliterate(str, options = {})
      Transliteration.perform(str, options)
    end
  end
end
