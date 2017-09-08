module ApiUmbrellaTestHelpers
  module SentEmails
    private

    # Recursively extract the MIME parts from Mailhog's response into an easier
    # to access structure (this assumes there's only one part of each content
    # type).
    def extract_mime(message, mime)
      message["_mime_parts"] ||= {}

      # Loop over each MIME part.
      if(mime && mime["Parts"])
        mime["Parts"].each do |part|
          content_types = part["Headers"]["Content-Type"]
          if(content_types && content_types.any?)
            # Extract the first Content-Type header (there should only be one),
            # and only pull out the primary part, ignoring extra suffix
            # information after the ";" (like charset).
            content_type = content_types.first.split(";").first.downcase

            # Extract the body text, taking into account base64 encoded
            # content.
            part = part.dup
            if(part["Body"] && part["Headers"]["Content-Transfer-Encoding"] == ["base64"])
              part["_body"] = Base64.decode64(part["Body"])
            else
              part["_body"] = part["Body"]
            end

            # Add this information in an easier to lookup hash.
            message["_mime_parts"][content_type] = part

            # Recursively extract MIME types, which accounts for nested
            # multipart/mixed entires.
            if(part["MIME"])
              extract_mime(message, part["MIME"])
            end
          end
        end
      end
    end

    def sent_emails
      response = Typhoeus.get("http://127.0.0.1:#{$config["mailhog"]["api_port"]}/api/v1/messages")
      assert_response_code(200, response)
      messages = MultiJson.load(response.body)

      messages.each do |message|
        extract_mime(message, message["MIME"])
      end

      messages
    end
  end
end
