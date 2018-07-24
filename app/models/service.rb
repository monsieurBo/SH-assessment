class Service < ApplicationRecord

	filterrific(
		default_filter_params: { sorted_by: 'name_asc' },
		available_filters: [
			:sorted_by,
			:search_query,
			:with_country,
			:with_price_lower,
			:with_price_higher,
			:with_cost_lower,
			:with_cost_higher
		]
	)

	self.per_page = 10

	# Scope definitions. We implement all Filterrific filters through ActiveRecord
  # scopes. In this example we omit the implementation of the scopes for brevity.
  # Please see 'Scope patterns' for scope implementation details.
  scope :search_query, lambda { |query|
    return nil  if query.blank?

    # condition query, parse into individual keywords
    terms = query.downcase.split(/\s+/)

    # replace "*" with "%" for wildcard searches,
    # append '%', remove duplicate '%'s
    terms = terms.map { |e|
			(e.gsub('%', '%') + '%').gsub(/%+/, '%')
    }
    # configure number of OR conditions for provision
    # of interpolation arguments. Adjust this if you
    # change the number of OR conditions.
    num_or_conditions = 2
    where(
      terms.map { 
        or_clauses = [
          "LOWER(services.name) ILIKE ?",
          "LOWER(services.country) ILIKE ?"
        ].join(' OR ')
        "(#{ or_clauses })"
      }.join(' AND '),
			*terms.map { |e| [e] * num_or_conditions }.flatten
		)
  }

  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
    case sort_option.to_s
    when /^name_/
      order("LOWER(services.name) #{ direction }")
    when /^price_/
      order("services.price #{ direction }")
    when /^country_/
      order("LOWER(services.country) #{ direction }")
    when /^cost_/
      order("services.cost #{ direction }")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }

  scope :with_country, lambda { |country|
    where(country: [*country])
  }

  scope :with_price_lower, lambda { |price|
    where('services.price < ?', price)
  }

  scope :with_price_higher, lambda { |price|
    where('services.price > ?', price)
  }

  scope :with_cost_lower, lambda { |cost|
    where('services.cost < ?', cost)
  }

  scope :with_cost_higher, lambda { |cost|
    where('services.cost > ?', cost)
  }

  def self.options_for_sorted_by
    [
      ['Name (a-z)', 'name_asc'],
      ['Price (highest first)', 'price_desc'],
      ['Price (lowest first)', 'price_asc'],
      ['Cost (highest first)', 'cost_desc'],
      ['Cost (lowest first)', 'cost_asc'],
      ['Country (a-z)', 'country_asc']
    ]
  end


  def self.options_for_select
    order(:country).map { |e| e.country }
  end


end
