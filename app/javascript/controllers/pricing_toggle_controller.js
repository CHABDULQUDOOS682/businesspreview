import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["projectBtn", "retainerBtn", "price"]

  toggle(event) {
    const type = event.currentTarget.dataset.type
    const isRetainer = type === "retainer"

    // Update buttons
    this.projectBtnTarget.className = `rounded-full px-5 py-2 text-sm font-semibold transition-all duration-300 ${!isRetainer ? 'bg-[#213885] text-[#ECDFD2] shadow-md shadow-[#213885]/25' : 'text-[#081849]/55 hover:text-[#081849]'}`
    this.retainerBtnTarget.className = `rounded-full px-5 py-2 text-sm font-semibold transition-all duration-300 ${isRetainer ? 'bg-[#213885] text-[#ECDFD2] shadow-md shadow-[#213885]/25' : 'text-[#081849]/55 hover:text-[#081849]'}`

    // Update prices
    this.priceTargets.forEach(price => {
      const projectPrice = price.dataset.projectPrice
      const retainerPrice = price.dataset.retainerPrice
      
      // Animate price change
      price.style.opacity = "0"
      price.style.transform = "translateY(-10px)"
      
      setTimeout(() => {
        price.textContent = isRetainer ? retainerPrice : projectPrice
        price.style.opacity = "1"
        price.style.transform = "translateY(0)"
      }, 200)
    })
  }
}
