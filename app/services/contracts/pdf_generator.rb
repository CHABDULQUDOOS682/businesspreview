# frozen_string_literal: true

require "prawn"
require "stringio"
require "tempfile"

class Contracts::PdfGenerator
  def initialize(contract)
    @contract = contract
  end

  def render
    Prawn::Document.new(page_size: "LETTER", margin: 54) do |pdf|
      pdf.font "Helvetica"
      pdf.text @contract.title.to_s, size: 18, style: :bold
      pdf.move_down 6
      pdf.text "#{@contract.kind_label} · #{@contract.status_label}", size: 10, color: "555555"
      pdf.move_down 16

      section(pdf, "Parties") do
        pdf.text "Service provider: #{@contract.agency_name}"
        pdf.text "Client: #{@contract.client_name} (#{@contract.client_email})"
      end

      section(pdf, "Scope of work") { pdf.text @contract.scope_of_work.to_s }
      section(pdf, "Pricing & payment") do
        if @contract.amount_cents.present?
          pdf.text "Amount: #{format('%.2f', @contract.amount)} #{@contract.currency.to_s.upcase}"
          pdf.move_down 6
        end
        pdf.text @contract.pricing_terms.to_s
      end
      section(pdf, "Timeline") { pdf.text @contract.timeline_terms.to_s }
      section(pdf, "Term & termination") { pdf.text @contract.termination_terms.to_s }

      if @contract.signed?
        section(pdf, "Signatures") do
          pdf.text "Client signer: #{@contract.client_signer_name}"
          pdf.text "Client signed at: #{@contract.client_signed_at&.utc&.iso8601}"
          pdf.text "Client IP: #{@contract.client_signer_ip}"
          embed_signature!(pdf)
          pdf.move_down 8
          pdf.text "Agency signer: #{@contract.agency_signer_name}"
          pdf.text "Agency signed at: #{@contract.agency_signed_at&.utc&.iso8601}"
        end
      end

      pdf.move_down 20
      pdf.text "Contract reference ##{@contract.id} · Generated #{Time.current.utc.iso8601}", size: 8, color: "777777"
    end.render
  end

  def attach!
    pdf_data = render
    filename = "contract-#{@contract.id}-#{@contract.status}.pdf"
    @contract.document.attach(
      io: StringIO.new(pdf_data),
      filename: filename,
      content_type: "application/pdf"
    )
    pdf_data
  end

  private

  def section(pdf, heading)
    pdf.text heading, size: 12, style: :bold
    pdf.move_down 6
    yield
    pdf.move_down 14
  end

  def embed_signature!(pdf)
    return unless @contract.client_signature.attached?

    Tempfile.create([ "signature", ".png" ]) do |file|
      file.binmode
      file.write(@contract.client_signature.download)
      file.flush
      pdf.move_down 8
      pdf.image file.path, fit: [ 220, 80 ]
    end
  rescue StandardError => e
    Rails.logger.warn("[Contracts::PdfGenerator] signature embed failed: #{e.message}")
  end
end
