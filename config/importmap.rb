pin 'application-spree-tcb', to: 'spree_tcb/application.js', preload: false

pin_all_from SpreeTcb::Engine.root.join('app/javascript/spree_tcb/controllers'),
             under: 'spree_tcb/controllers',
             to:    'spree_tcb/controllers',
             preload: 'application-spree-tcb'
