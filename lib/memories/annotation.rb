module Memories
  class Annotation < Hash
    def method_missing(method_name, *args, &block)
      if args.empty?
        self[method_name]
      else
        self[method_name] = args[0]
      end
    end
  end
end
