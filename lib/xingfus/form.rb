require 'mime/types'

module Xingfus
  class Form
    attr_accessor :params
    attr_reader :traversal

    def initialize(params = {})
      @params = params
    end

    def traversal
      @traversal ||= Xingfus::Utils.traverse_params_hash(params)
    end

    def process!
      # add params
      traversal[:params].each { |p| formadd_param(Xingfus::Utils.escape(p[0]), multipart? ? p[1] : Xingfus::Utils.escape(p[1])) }

      # add files
      traversal[:files].each { |file_args| formadd_file(*file_args) }
    end

    def multipart?
      !traversal[:files].empty?
    end

    def to_s
      Xingfus::Utils.traversal_to_param_string(traversal)
    end
  end
end
