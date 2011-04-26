#
# Sonar, entreprise quality control tool.
# Copyright (C) 2008-2011 SonarSource
# mailto:contact AT sonarsource DOT com
#
# Sonar is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# Sonar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with Sonar; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02
#

require "json"

class Api::ReviewsController < Api::ApiController

  include MarkdownHelper

  def index
    convert_markdown=(params[:html]=='true')
    reviews=Review.search(params)
    
    respond_to do |format|
      format.json { render :json => jsonp(to_json(reviews, convert_markdown)) }
      format.xml {render :xml => to_xml(reviews, convert_markdown)}
      format.text { render :text => text_not_supported }
    end
  end


  private

  def to_xml(reviews, convert_markdown)
    xml = Builder::XmlMarkup.new(:indent => 0)
    xml.instruct!
    
    xml.reviews do
      reviews.each do |review|
        xml.review do
          xml.id(review.id.to_i)
          xml.updatedAt(format_datetime(review.updated_at))
          xml.user(review.user.login)
          xml.assignee(review.assignee.login)
          xml.title(review.title)
          xml.type(review.review_type)
          xml.status(review.status)
          xml.severity(review.severity)
          xml.resource(review.resource.kee)  if review.resource
          xml.line(review.resource_line) if review.resource_line
          
          # Continue here with resource + comments
        end
      end
    end
  end
  
  def to_json(reviews, convert_markdown=false)
    JSON(reviews.collect{|review| review_to_json(review, convert_markdown)})
  end

  def review_to_json(review, html=false)
    json = {}
    json['id'] = review.id.to_i
    json['updatedAt'] = review.updated_at
    json['author'] = review.user.login
    json['assignee'] = review.assignee.login if review.assignee
    json['title'] = review.title if review.title
    json['type'] = review.review_type
    json['status'] = review.status
    json['severity'] = review.severity
    comments = []
    review.review_comments.each do |comment|
      comments << {
        'author' => comment.user.login,
        'updatedAt' => format_datetime(comment.updated_at),
        'comment' => (html ? markdown_to_html(comment.review_text): comment.review_text)
      }
    end
    json['comments'] = comments
    json['line'] = review.resource_line if review.resource_line
    json['resource'] = review.resource.kee if review.resource
    json
  end

end