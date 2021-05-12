# Backports for nice things.

ENV.instance_eval do
  def merge! hsh
    hsh.each { |k, v| ENV[k] = v }
  end

  # For some reason, `alias` doesn't work here in MRuby
  # alias merge! update
  def update hsh
    merge! hsh
  end
end unless ENV.respond_to?(:merge!) && ENV.respond_to?(:update)
