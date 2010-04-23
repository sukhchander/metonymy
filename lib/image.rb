class Image < ActiveRecord::Base
    after_save :update_image_id

    def url size
        [API_IMG,self.id,size.to_s,self.file_name].join('/')
    end

private
    def update_image_id
        CACHE.set("curr_image_id",self.id.to_i)
        # MemCacheError: cannot increment or decrement non-numeric value
        CACHE.set("prev_image_id",self.id.to_i-1)
        CACHE.set("next_image_id",self.id.to_i+1)
    end
end
