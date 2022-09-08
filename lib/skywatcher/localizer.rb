require 'skywatcher/locale'
require 'skywatcher/data/locales'

module Skywatcher
  class Localizer
    def initialize(kind, id)
      @kind = kind
      @id = id
    end

    attr_reader :kind, :id

    def [](locale)
      to_h[locale] || id.to_s
    end

    def to_h
      @hash ||= Data::Locales::MAP.map { |lid, locale| [lid, locale.__send__(kind)[id]] }.select { |(_,v)| v }.to_h
    end
  end
end
