require 'play_store_info/readers'

module PlayStoreInfo
  class AppParser
    include PlayStoreInfo::Readers

    readers %w(id name artwork description current_rating rating_count genre_names url price author)

    def initialize(id, body)
      @id = id
      @body = body

      scrape_data

      self
    end

    private

    def read_id
      @id
    end

    def read_name
      name = @body.xpath('//h1//span[@itemprop="name"]').text

      raise ParsingError if name.empty?

      # get the app proper name in case the title contains some description
      name
    end

    def read_artwork
      url = @body.xpath('//img[@itemprop="image"]/@src').first&.value&.strip || ''

      # add the HTTP protocol if the image source is lacking http:// because it starts with //
      url.match(%r{^https?:\/\/}).nil? ? "http://#{url.gsub(%r{\A\/\/}, '')}" : url
    end

    def read_description
      description = @body.xpath('//div[@data-g-id="description"]').first&.inner_html&.strip

      description.nil? ? '' : Sanitize.fragment(description).strip
    end

    def read_current_rating
      current_rating = parsed_json.dig('aggregateRating', 'ratingValue')
      current_rating.nil? ? '' : current_rating.strip
    end

    def read_rating_count
      rating_count = parsed_json.dig('aggregateRating', 'ratingCount')
      rating_count.nil? ? '' : rating_count.split(",").join().strip
    end

    def read_genre_names
      genre_names = []
      @body.xpath('//div[@itemprop="genre"]').each do |tag|
        genre_names << tag.text
      end
      genre_names
    end

    def read_url
      url = parsed_json.dig('url')
      url.match(%r{^https?:\/\/}).nil? ? "http://#{url.gsub(%r{\A\/\/}, '')}" : url
    end

    def read_price
      price = @body.xpath('//meta[@itemprop="price"]/@content').first&.value&.strip || ''
      price.nil? ? '' : price.strip
    end

    def read_author
      author = parsed_json.dig('author', 'name')
      author.nil? ? '' : author.strip
    end

    def parsed_json
      @parsed_json ||= begin
        json_content = @body.xpath('//script[@type="application/ld+json"]').text
        JSON.parse(json_content)
      end
    end

  end
end
