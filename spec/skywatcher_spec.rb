RSpec.describe Skywatcher do
  it "has a version number" do
    expect(Skywatcher::VERSION).not_to be nil
  end

  Skywatcher::Data::Locales::MAP.each do |lang, locale|
    weathers = locale.weather.keys
    Skywatcher::Data::Weathers::LIST.each do |weather|
      it "has defined #{weather} translation in #{lang}" do
        expect(weathers).to be_include(weather)
      end
    end

    zones = locale.zone.keys
    Skywatcher::Data::Zones::MAP.each do |zone, _|
      it "has defined #{zone} translation in #{lang}" do
        expect(zones).to be_include(zone)
      end
    end
  end

  Skywatcher::Data::Zones::MAP.each do |_, zone|
    it "has defined weathers at #{zone.id}" do
      zone.rates.each do |chance, weather|
        expect(Skywatcher::Data::Weathers::LIST).to be_include(weather)
      end
    end
  end
end
