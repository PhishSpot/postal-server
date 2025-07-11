# frozen_string_literal: true

class API::V1::DNSRecordsSerializer
  def initialize(domain)
    @domain = domain
  end

  def as_json
    {
      domain: @domain.name,
      last_checked_at: @domain.dns_checked_at&.iso8601,
      instructions: "Add these DNS records to your domain's DNS settings to ensure proper email delivery",
      note: "Allow up to 24 hours for DNS propagation. Check records after setup using the check_dns endpoint.",
      records: dns_records,
      summary: dns_summary
    }
  end

  private

  def dns_records
    {
      spf: spf_record,
      dkim: dkim_record,
      return_path: return_path_record,
      mx: mx_record
    }
  end

  def spf_record
    {
      type: 'TXT',
      name: '@',
      value: @domain.spf_record,
      status: @domain.spf_status,
      error: @domain.spf_error,
      description: "Add this TXT record for the subdomain. If you already send mail from another service, you may just need to add 'include:#{Postal::Config.dns.spf_include}' to your existing record."
    }
  end

  def dkim_record
    {
      type: 'TXT',
      name: @domain.dkim_record_name,
      value: @domain.dkim_record,
      status: @domain.dkim_status,
      error: @domain.dkim_error,
      description: "Add this TXT record with the exact name shown above. This record contains your domain's public DKIM key."
    }
  end

  def return_path_record
    {
      type: 'CNAME',
      name: @domain.return_path_domain,
      value: Postal::Config.dns.return_path_domain,
      status: @domain.return_path_status,
      error: @domain.return_path_error,
      description: "Optional but recommended. Add this CNAME record to improve deliverability and achieve DMARC alignment."
    }
  end

  def mx_record
    {
      type: 'MX',
      name: '@',
      value: Postal::Config.dns.mx_records,
      priority: 10,
      status: @domain.mx_status,
      error: @domain.mx_error,
      description: "Add these MX records for the subdomain if you want to receive incoming email. Both records should have priority 10."
    }
  end

  def dns_summary
    statuses = [@domain.spf_status, @domain.dkim_status, @domain.return_path_status, @domain.mx_status]
    
    {
      total_records: 4,
      required_records: 2,
      optional_records: 2,
      ok_count: statuses.count('OK'),
      warning_count: statuses.count { |s| s.present? && s != 'OK' && s != 'Missing' },
      missing_count: statuses.count('Missing') + statuses.count(nil)
    }
  end
end
