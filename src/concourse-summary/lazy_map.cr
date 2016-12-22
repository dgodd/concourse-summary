class Array(T)
  def lazy_map(&block : T -> U) forall U
    ch = Channel(Tuple(Int32,U)).new(size)
    self.each_with_index do |obj,i|
      spawn do
        ch.send({i, block.call(obj)})
      end
    end
    Array(Tuple(Int32,U))
      .new(size) { ch.receive }
      .sort_by(&.[0])
      .map(&.[1])
  end
end
