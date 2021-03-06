class Api
  include HTTParty

  base_uri 'https://brasil.io/api/dataset/covid19'

  def initialize(page)
    @options = { query: { format: 'json', page: page } }
  end

  def caso
    self.class.get('/caso/data', @options)
  end

  def results
    caso['results']
  end

  def count
    caso['count']
  end

  def next
    caso['next']
  end

  def previous
    caso['previous']
  end

  def self.dataset(page)
    api_dataset = Api.new(page)

    if api_dataset.next.nil?
      return api_dataset.results
    else
      return api_dataset.results + dataset(page + 1)
    end
  end

  def self.setup
    api_dataset = Api.dataset(1)
    dataset = Dataset.create!(results: api_dataset)
    results = dataset.results

    # confirmed_by_date = results.select{ |h| h['place_type'] == 'city' }.group_by{ |h| h['date']  }

    # confirmed_by_date.each do |date, cases|
    #   total = cases.sum{ |h| h['confirmed'] }

    #   cases_by_date = CasesByDate.find_by(date: date)

    #   if cases_by_date.present?
    #     cases_by_date.update_attributes(total: total)
    #   else
    #     CasesByDate.create!(
    #       date: date,
    #       total: total
    #     )
    #   end
    # end

    states_log = results.select{ |h| h['place_type'] == 'state' }.group_by{ |h| h['state']  }
    states = []
    states_log.each do |uf, state_row|
      last_state = state_row.find{ |h| h['is_last'] }

      state = State.new(uf: last_state['state'],
                    deaths: last_state['deaths'] || 0,
                    confirmed: last_state['confirmed'] || 0,
                    ibge_code: last_state['city_ibge_code'],
                    confirmed_per_100k_inhabitants: last_state['confirmed_per_100k_inhabitants'] || 0,
                    date: last_state['date'],
                    death_rate: last_state['death_rate'] || 0,
                    estimated_population_2019: last_state['estimated_population_2019'] || 0,
                    state_history: StateHistory.new(log: state_row))

      state.upsert
      states << state
    end

    # cities_log = results.select{ |h| h['place_type'] == 'city' }.group_by{ |h| h['city_ibge_code']  }

    # cities_log.each do |ibge_code, cities_row|
    #   last_update = cities_row.find{ |h| h['is_last'] }

    #   city = City.new(name: last_update['city'],
    #                   uf: last_update['state'],
    #                   deaths: last_update['deaths'] || 0,
    #                   confirmed: last_update['confirmed'] || 0,
    #                   ibge_code: last_update['city_ibge_code'],
    #                   confirmed_per_100k_inhabitants: last_update['confirmed_per_100k_inhabitants'] || 0,
    #                   date: last_update['date'],
    #                   death_rate: last_update['death_rate'] || 0,
    #                   estimated_population_2019: last_update['estimated_population_2019'] || 0,
    #                   city_history: CityHistory.new(log: cities_row))

    #   city.upsert

    #   states.each do |state|
    #     state.cities << city if state.uf == city.uf
    #   end
    # end
  end
end
