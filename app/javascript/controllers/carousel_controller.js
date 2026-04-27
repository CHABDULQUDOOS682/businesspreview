import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"

// Connects to data-controller="carousel"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.swiper = new Swiper(this.containerTarget, {
      effect: 'coverflow',
      grabCursor: true,
      centeredSlides: true,
      slidesPerView: 'auto',
      loop: true,
      speed: 800,
      autoplay: {
        delay: 4000,
        disableOnInteraction: false,
      },
      coverflowEffect: {
        rotate: 15,
        stretch: 0,
        depth: 200,
        modifier: 1,
        slideShadows: false,
      },
      pagination: {
        el: '.swiper-pagination',
        clickable: true,
        dynamicBullets: true,
      },
      navigation: {
        nextEl: '.swiper-button-next',
        prevEl: '.swiper-button-prev',
      },
      breakpoints: {
        320: {
          slidesPerView: 1.2,
          coverflowEffect: {
            rotate: 5,
            depth: 100,
          }
        },
        768: {
          slidesPerView: 2,
          coverflowEffect: {
            rotate: 10,
            depth: 150,
          }
        },
        1024: {
          slidesPerView: 3,
          coverflowEffect: {
            rotate: 15,
            depth: 200,
          }
        }
      }
    })
  }

  disconnect() {
    if (this.swiper) {
      this.swiper.destroy()
    }
  }
}
