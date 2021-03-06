test_name 'C3612 - checkout a tag that does not exist'

# Globals
repo_name = 'testrepo_tag_checkout'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup - create repo' do
    git_pkg = 'git'
    if host['platform'] =~ %r{ubuntu-10}
      git_pkg = 'git-core'
    end
    install_package(host, git_pkg)
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../../..'))
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    on(host, "cd #{tmpdir} && ./create_git_repo.sh")
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
  end

  step 'checkout tag that does not exist with puppet' do
    pp = <<-MANIFEST
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "file://#{tmpdir}/testrepo.git",
      provider => git,
      tag => '11111111111111111',
    }
    MANIFEST

    apply_manifest_on(host, pp, catch_failures: true)
    apply_manifest_on(host, pp, catch_changes: true)
  end

  step 'verify that master tag is checked out' do
    on(host, "ls #{tmpdir}/#{repo_name}/.git/") do |res|
      fail_test('checkout not found') unless res.stdout.include? 'HEAD'
    end

    on(host, "cat #{tmpdir}/#{repo_name}/.git/HEAD") do |res|
      fail_test('tag not found') unless res.stdout.include? 'ref: refs/heads/master'
    end
  end
end
