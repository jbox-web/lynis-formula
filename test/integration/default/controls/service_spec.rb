# frozen_string_literal: true

control 'Lynis periodic audit' do
  title 'should be scheduled by a systemd timer'

  describe file('/etc/systemd/system/lynis.service') do
    its('content') { should include 'ExecStart=/usr/sbin/lynis audit system --cronjob' }
  end

  describe file('/etc/systemd/system/lynis.timer') do
    its('content') { should include 'OnCalendar=weekly' }
    its('content') { should include 'RandomizedDelaySec=6h' }
    its('content') { should include 'Persistent=true' }
  end

  describe systemd_service('lynis.timer') do
    it { should be_enabled }
    it { should be_running }
  end
end
