# Spree Tcb

This is a Tcb extension for [Spree Commerce](https://spreecommerce.org), an open source e-commerce platform built with Ruby on Rails. This extension contains custom functionality for TCB's employee ordering system.

## Features

### Multi-Tenancy Support
Complete data isolation between stores (tenants) with shared infrastructure:
- Each Spree::Store acts as a tenant with isolated data
- Products, orders, users, and configurations are tenant-specific
- Shared reference data (countries, states) across all tenants
- Automatic tenant scoping for all queries and creates

**Create a new tenant:**
```bash
bundle exec rake spree_tcb:multi_tenant:create_tenant[name,code,url,email]
```

**Assign existing data to a tenant:**
```bash
bundle exec rake spree_tcb:multi_tenant:assign_to_tenant[store_code]
```

**Switch tenant context (console/testing):**
```ruby
store = Spree::Store.find_by(code: 'tcb')
SpreeTcb::MultiTenant.with_tenant(store) do
  # All operations are scoped to this tenant
  Spree::Product.all # Only shows products for 'tcb' store
end
```

### Per-Store Registration Control
This extension allows you to disable user registration on a per-store basis, perfect for employee-only stores or multi-tenant configurations.

**Disable registration for a store:**
```ruby
store = Spree::Store.find_by(code: 'your_store_code')
store.set_preference(:registration_disabled, true)
store.save!
```

**Enable registration for a store:**
```ruby
store = Spree::Store.find_by(code: 'your_store_code')
store.set_preference(:registration_disabled, false)
store.save!
```

When registration is disabled:
- Signup links are hidden from the login page
- Direct access to registration URLs redirects to login
- Users see a message to contact their administrator for account access

### Employee Payment Method
Includes a "No Payment Required" payment method for employee orders that:
- Auto-approves orders without payment details
- Generates employee-specific authorization codes
- Streamlines checkout for internal ordering

### Address Geocoding
Automatically geocodes addresses and stock locations using OpenCage:
- Adds latitude/longitude to addresses and stock locations
- Triggers on address changes or new records
- Requires OpenCage API key in Rails credentials

## Installation

1. Add this extension to your Gemfile with this line:

    ```ruby
    bundle add spree_tcb
    ```

2. Run the install generator

    ```ruby
    bundle exec rails g spree_tcb:install
    ```

3. Restart your server

  If your server was running, restart it so that it can find the assets properly.

## Developing

1. Create a dummy app

    ```bash
    bundle update
    bundle exec rake test_app
    ```

2. Add your new code
3. Run tests

    ```bash
    bundle exec rspec
    ```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_tcb/factories'
```

## Releasing a new version

```shell
bundle exec gem bump -p -t
bundle exec gem release
```

For more options please see [gem-release README](https://github.com/svenfuchs/gem-release)

## Contributing

If you'd like to contribute, please take a look at the
[instructions](CONTRIBUTING.md) for installing dependencies and crafting a good
pull request.
