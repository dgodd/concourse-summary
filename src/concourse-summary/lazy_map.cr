class Array(T)
  def lazy_map(&block : T -> U) forall U
    ch = Channel(U).new(size)
    self.each do |d|
      spawn do
        ch.send(block.call d)
      end
    end
    Array(U).new(size) { |i| ch.receive }
  end
end
