module Sitemapper
  class Builder

    getter paginator
    
    def initialize(@host : String, @max_urls : Int32, @use_index : Bool)
      @paginator = Paginator.new(limit: @max_urls)
      @sitemaps = [] of Hash(String, String)
    end

    def add(path, **kwargs)
      options = SitemapOptions.new(**kwargs)
      @paginator.add(path, options)
    end

    def generate
      @paginator.total_pages.times do |page|
        filename = filename_for_page(page)
        doc = XML.build(indent: " ", version: "1.0", encoding: "UTF-8") do |xml|
          xml.element("urlset", xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
            @paginator.items(page + 1).each do |info|
              build_xml_from_info(xml, info)
            end
          end
        end

        @sitemaps << {"name" => filename, "data" => doc}
      end

      if @use_index
        doc = XML.build(indent: " ", version: "1.0", encoding: "UTF-8") do |xml|
          xml.element("sitemapindex", xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
            @sitemaps.each do |sm|
              xml.element("sitemap") do
                xml.element("loc") { xml.text [@host, sm["name"]].join('/') }
                xml.element("lastmod") { xml.text Time.now.to_s("%FT%X%:z") }
              end
            end
          end 
        end
        filename = "sitemap_index.xml"
        @sitemaps << {"name" => filename, "data" => doc}
      end

      @sitemaps
    end

    private def build_xml_from_info(xml, info)
      path = info[0].as(String)
      options = info[1].as(SitemapOptions)

      xml.element("url") do
        xml.element("loc") { xml.text [@host, path].join }
        xml.element("lastmod") { xml.text options.lastmod.as(Time).to_s("%FT%X%:z") }
        xml.element("changefreq") { xml.text options.changefreq.to_s }
        xml.element("priority") { xml.text options.priority.to_s }
        unless options.video.nil?
          options.video.as(VideoMap).render_xml(xml)
        end
        unless options.image.nil?
          options.image.as(ImageMap).render_xml(xml)
        end
      end
    end

    private def filename_for_page(page)
      if @paginator.total_pages == 1
        "sitemap.xml"
      else
        "sitemap#{page + 1}.xml"
      end
    end

  end
end
