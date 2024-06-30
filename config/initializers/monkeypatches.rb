module Enumerable
  def only!
    if self.length == 1
      self.first
    else
      raise "#{self.class.to_s.split('::').first}.only! with #{self.length} elements"
    end
  end
end
