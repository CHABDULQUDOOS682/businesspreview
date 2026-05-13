require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_link_to" do
    before do
      allow(helper).to receive(:current_page?).and_return(false)
    end

    it "returns an anchor tag with inactive classes" do
      result = helper.nav_link_to("Home", root_path)
      expect(result).to include('class="rounded-full px-4 py-2 text-sm font-semibold text-slate-600 transition hover:bg-white/80 hover:text-slate-950"')
    end

    it "returns an anchor tag with active classes when on current page" do
      allow(helper).to receive(:current_page?).with(root_path).and_return(true)
      result = helper.nav_link_to("Home", root_path)
      expect(result).to include('class="rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white"')
    end
  end

  describe "#visible_business_segment_tabs" do
    let(:tabs) { [ { key: "nurture" }, { key: "purchased" } ] }

    it "returns all tabs for non-employee roles" do
      allow(helper).to receive(:respond_to?).with(:employee_role?, any_args).and_return(true)
      allow(helper).to receive(:employee_role?).and_return(false)
      expect(helper.visible_business_segment_tabs(tabs)).to eq(tabs)
    end

    it "returns only nurture tabs for employee roles" do
      allow(helper).to receive(:respond_to?).with(:employee_role?, any_args).and_return(true)
      allow(helper).to receive(:employee_role?).and_return(true)
      expect(helper.visible_business_segment_tabs(tabs)).to eq([ { key: "nurture" } ])
    end
  end
end
