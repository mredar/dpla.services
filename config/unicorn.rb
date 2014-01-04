root = '/home/fenne035/dev/dpla/dpla.services'

working_directory root
pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/unicorn/unicorn.log"
stdout_path "#{root}/unicorn/unicorn.log"

# listen "/tmp/unicorn.dplahub.sock"
listen 8083, :tcp_nopush => true
worker_processes 2
timeout 60