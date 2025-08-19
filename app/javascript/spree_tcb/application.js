import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'

let application

if (typeof window.Stimulus === "undefined") {
  application = Application.start()
  application.debug = false
  window.Stimulus = application
} else {
  application = window.Stimulus
}

import SpreeTcbController from 'spree_tcb/controllers/spree_tcb_controller' 

application.register('spree_tcb', SpreeTcbController)