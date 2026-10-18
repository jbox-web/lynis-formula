# frozen_string_literal: true

control 'Lynis configuration' do
  title 'should match desired lines'

  describe file('/etc/lynis/foo.prf') do
    its('content') { should include 'skip-test=LYNIS' }
  end

  # rubocop:disable Layout/LineLength
  describe file('/etc/lynis/bar.prf') do
    its('content') { should include 'skip-test=KRNL-5788' }
    its('content') { should include 'skip-test=KRNL-6000:net.ipv4.conf.all.log_martians' }
  end
  # rubocop:enable Layout/LineLength

  # The pillar lists KRNL-5788 twice with the same description.
  describe file('/etc/lynis/bar.prf').content.lines.count("skip-test=KRNL-5788\n") do
    it { should cmp 1 }
  end
end
