### **Case Study: "Saras Mini-Commerce" Data Warehouse**

#### **Business Context**

Saras Mini-Commerce is a rapidly growing D2C ecommerce platform founded in 2020 that has expanded from a small selection of basic apparel to a comprehensive catalog featuring premium clothing, accessories, and lifestyle products. After securing a Series B funding round of $25M, the company is scaling operations across North America and planning to enter European markets by Q3 this year.

With over 50,000 monthly active customers and growing competition in the D2C space, the leadership team needs sophisticated analytics to drive strategic decisions. The CEO, has emphasized that data-driven insights will be critical for the company's next growth phase.

**Current Business Challenges:**

* **Profitability Analysis**: Which product variants deliver the highest margins while maintaining strong conversion rates? The merchandising team needs this data to optimize the product catalog.

* **Marketing Efficiency**: With a monthly ad spend exceeding $500K across multiple channels, the marketing team needs to understand customer acquisition costs and lifetime value by channel and cohort to optimize budget allocation.

* **Customer Behavior**: The UX team has noted significant differences in purchase patterns between new and returning customers but lacks quantitative data on funnel conversion disparities.

* **Product Development**: The product team wants to identify which specific product attributes (materials, styles, etc.) correlate most strongly with repeat purchases to inform future design decisions.

* **Customer Attribution**: The marketing team needs to build a first-touch and multi-touch attribution model using session and order data to understand which channels are most effective at acquiring high-value customers.

* **Inventory Management**: With warehouse costs increasing and stockouts affecting customer satisfaction, the operations team needs variant-level inventory turnover analysis to optimize stocking levels.

The CTO has tasked you with building a robust data warehouse that will serve as the foundation for these critical business decisions. Your work will directly impact the company's ability to maintain its growth trajectory while improving unit economics.

---

### **Raw Table Schemas (BigQuery-style)**

#### `raw_customers` (enhanced with nested demographics and metrics)

| Column                      | Type         | Description                                     | Notes                                         |
| --------------------------- | ------------ | ----------------------------------------------- | --------------------------------------------- |
| customer\_id                | STRING       | Unique customer identifier                      | PK, but some NULLs and duplicates             |
| profile                     | RECORD       | Customer profile information                    | Nested record                                 |
| profile.first\_name         | STRING       | Customer's first name                           | Sometimes inconsistent capitalization         |
| profile.last\_name          | STRING       | Customer's last name                            | Sometimes inconsistent capitalization         |
| profile.emails              | ARRAY<STRING>| List of customer email addresses                | Primary email is first in array               |
| profile.phones              | ARRAY<STRING>| List of customer phone numbers                  | Various formats, some invalid                 |
| profile.demographics        | RECORD       | Customer demographic data                       | Nested record with demographic information    |
| profile.demographics.age\_range | STRING   | Age range                                       | e.g. '18-24', '25-34', '35-44'               |
| profile.demographics.gender | STRING       | Gender                                          | e.g. 'Male', 'Female', 'Other', 'Prefer not to say' |
| profile.demographics.location\_data | RECORD | Location metadata                            | Nested record with location details           |
| profile.demographics.location\_data.city\_tier | STRING | City tier classification           | e.g. 'Tier 1', 'Tier 2', 'Tier 3'            |
| profile.demographics.location\_data.region | STRING | Geographic region                      | e.g. 'Northeast', 'West', 'South'             |
| profile.demographics.location\_data.timezone | STRING | Customer timezone                    | e.g. 'America/New_York', 'Europe/London'      |
| signup\_ts                  | TIMESTAMP    | When customer account was created               | Some rows as STRING timestamps                |
| marketing\_preferences      | RECORD       | Customer marketing preferences                  | Nested record                                 |
| marketing\_preferences.channels | ARRAY<STRING> | Preferred marketing channels               | e.g. ['email', 'sms', 'push']                |
| marketing\_preferences.preferred\_channel | STRING | Primary preferred channel               | Sometimes NULL                                |
| marketing\_preferences.frequency | STRING  | Preferred contact frequency                     | e.g. 'Daily', 'Weekly', 'Monthly'             |
| marketing\_preferences.interests | ARRAY<STRING> | Interest categories                      | e.g. ['Menswear', 'Outdoor', 'Sale']          |
| marketing\_preferences.unsubscribed\_channels | ARRAY<STRING> | Unsubscribed channels       | Channels customer has opted out from          |
| address                     | RECORD       | Customer address information                    | Nested record                                 |
| address.street              | STRING       | Street address                                  | Sometimes includes apt/unit numbers           |
| address.city                | STRING       | City                                            | Sometimes inconsistent capitalization         |
| address.state               | STRING       | State/province                                  | Mix of full names and abbreviations           |
| address.zip                 | STRING       | Postal/zip code                                 | Various formats                               |
| address.country             | STRING       | Country                                         | Mix of full names and ISO codes               |
| first_seen_date             | TIMESTAMP    | Date customer was first seen                    | Can be used with sessions for attribution     |
| is\_deleted                 | BOOLEAN      | Whether customer is deleted                     | Rows with TRUE should be filtered out         |

---

#### `raw_orders` (enhanced with variant-level data and metrics)

| Column                 | Type          | Description                                     | Notes                                        |
| ---------------------- | ------------- | ----------------------------------------------- | -------------------------------------------- |
| order\_id              | STRING        | Unique order identifier                         | PK                                           |
| customer\_id           | STRING        | Customer who placed the order                   | FK to raw\_customers, some missing           |
| order\_ts              | TIMESTAMP     | When order was placed                           | Some in wrong timezone                       |
| items                  | ARRAY<RECORD> | Products ordered                                | Array of order items                         |
| items.product\_id      | STRING        | Product identifier                              | FK to raw\_products                          |
| items.variant\_id      | STRING        | Variant identifier                              | FK to raw\_products.variants                 |
| items.qty              | INT64         | Quantity ordered                                | Sometimes zero or negative (data errors)     |
| items.price            | NUMERIC       | Unit price at time of order                     | May differ from current product price        |
| items.discount         | NUMERIC       | Discount amount per unit                        | Zero if no discount applied                  |
| items.attributes       | RECORD        | Item-specific attributes                        | Nested record with item details              |
| items.attributes.color | STRING        | Selected color                                  | Color of purchased variant                   |
| items.attributes.size  | STRING        | Selected size                                   | Size of purchased variant                    |
| items.attributes.personalization | STRING | Custom personalization                       | Any personalized text/options                |
| items.metrics          | RECORD        | Item-level metrics                              | Nested record with financial metrics         |
| items.metrics.margin   | NUMERIC       | Item profit margin                              | (price - cost) / price                       |
| items.metrics.cost     | NUMERIC       | Item cost                                       | Cost at time of order                        |
| items.metrics.tax      | NUMERIC       | Item tax amount                                 | Tax charged on item                          |
| payment                | RECORD        | Payment information                             | Nested record                                |
| payment.method         | STRING        | Payment method used                             | e.g. 'credit_card', 'paypal', 'apple_pay'   |
| payment.status         | STRING        | Payment status                                  | e.g. 'completed', 'failed', 'pending'       |
| payment.txn\_id        | STRING        | Payment processor transaction ID                | External reference ID                        |
| shipping\_address      | RECORD        | Shipping address                                | Nested record                                |
| shipping\_address.street | STRING      | Street address for shipping                     | May differ from customer address             |
| shipping\_address.city | STRING        | City for shipping                               | May differ from customer address             |
| shipping\_address.state | STRING       | State/province for shipping                     | May differ from customer address             |
| shipping\_address.zip  | STRING        | Postal/zip code for shipping                    | May differ from customer address             |
| shipping\_address.country | STRING     | Country for shipping                            | May differ from customer address             |
| source\_channel        | STRING        | Sales channel                                   | e.g. `web`, `mobile`, `in-store`             |
| utm\_source            | STRING        | Traffic source                                  | Marketing attribution source (sometimes NULL)|
| utm\_campaign          | STRING        | Marketing campaign                              | Campaign name (sometimes NULL)               |
| utm\_medium            | STRING        | Marketing medium                                | Medium (sometimes NULL)                      |
| shipping\_cost         | NUMERIC       | Cost of shipping                                | Shipping cost for the order                  |
| status                 | STRING        | Order status                                    | 'completed', 'cancelled', 'returned', 'pending' |

---

#### `raw_products` (enhanced with nested variants and attributes)

| Column              | Type          | Description                                     | Notes                                         |
| ------------------- | ------------- | ----------------------------------------------- | --------------------------------------------- |
| product\_id         | STRING        | Unique product identifier                       | PK                                            |
| name                | STRING        | Product name                                    | Sometimes blank                               |
| description         | STRING        | Product description                             | Sometimes NULL                                |
| category\_hierarchy | ARRAY<STRING> | Product category path                           | e.g. \['Apparel', 'Men', 'Shirts']           |
| attributes          | RECORD        | Product attributes                              | Nested record with product details            |
| attributes.material | STRING        | Material composition                            | e.g. 'Cotton', 'Polyester'                   |
| attributes.brand    | STRING        | Brand name                                      | Internal or partner brand                     |
| attributes.season   | STRING        | Seasonal collection                             | e.g. 'Summer 2023', 'Winter 2023'            |
| attributes.style    | RECORD        | Style information                               | Nested record with style details              |
| attributes.style.fit | STRING       | Product fit                                     | e.g. 'Regular', 'Slim', 'Loose'              |
| attributes.style.pattern | STRING   | Product pattern                                 | e.g. 'Solid', 'Striped', 'Floral'            |
| attributes.style.occasion | ARRAY<STRING> | Suitable occasions                        | e.g. ['Casual', 'Formal', 'Athletic']        |
| attributes.sustainability | RECORD   | Sustainability information                     | Nested record with eco details                |
| attributes.sustainability.eco\_friendly | BOOLEAN | Eco-friendly status               | Whether product is eco-friendly               |
| attributes.sustainability.certifications | ARRAY<STRING> | Eco certifications         | e.g. ['Organic', 'Fair Trade']               |
| variants            | ARRAY<RECORD> | Product variants                                | Array of variant records                      |
| variants.variant\_id | STRING       | Unique variant identifier                       | Variant PK                                    |
| variants.sku        | STRING        | Stock keeping unit                              | Unique SKU for inventory                      |
| variants.color      | STRING        | Variant color                                   | e.g. 'Red', 'Blue', 'Green'                  |
| variants.size       | STRING        | Variant size                                    | e.g. 'S', 'M', 'L', 'XL'                     |
| variants.images     | ARRAY<STRING> | Variant images                                  | URLs to variant images                        |
| variants.cost\_price | NUMERIC      | Variant-specific cost                           | May differ from base product cost             |
| variants.retail\_price | NUMERIC    | Variant-specific price                          | May differ from base product price            |
| variants.inventory  | RECORD        | Variant inventory settings                      | Nested record with inventory parameters       |
| variants.inventory.initial\_stock | INTEGER | Initial stocking quantity               | Starting inventory level                      |
| variants.inventory.restock\_threshold | INTEGER | Reorder threshold                   | Level at which to restock                     |
| variants.attributes | RECORD        | Variant-specific attributes                     | Nested record with variant details            |
| variants.attributes.weight | NUMERIC | Product weight                                 | Weight in grams                               |
| variants.attributes.dimensions | RECORD | Product dimensions                          | Nested record with size details               |
| variants.attributes.dimensions.length | NUMERIC | Product length                      | Length in cm                                  |
| variants.attributes.dimensions.width | NUMERIC | Product width                        | Width in cm                                   |
| variants.attributes.dimensions.height | NUMERIC | Product height                      | Height in cm                                  |
| cost\_price         | NUMERIC       | Base wholesale/manufacturing cost               | Base cost for default variant                 |
| retail\_price       | NUMERIC       | Base suggested retail price                     | MSRP/list price for default variant           |
| created\_at         | TIMESTAMP     | When product was created                        | When product was added to catalog             |
| updated\_at         | TIMESTAMP     | When product was last updated                   | Last update timestamp                         |
| is\_active          | BOOLEAN       | Whether product is active                       | false → inactive product                      |

---

#### `raw_inventory_snapshots` (enhanced with variant-level tracking)

| Column              | Type      | Description                                     | Notes                                          |
| ------------------- | --------- | ----------------------------------------------- | ---------------------------------------------- |
| snapshot\_id        | STRING    | Unique snapshot identifier                      | PK                                             |
| snapshot\_date      | DATE      | Date of inventory snapshot                      | Daily snapshots                                |
| product\_id         | STRING    | Product identifier                              | FK to raw\_products                            |
| variant\_id         | STRING    | Variant identifier                              | FK to raw\_products.variants                   |
| warehouse\_id       | STRING    | Warehouse identifier                            | Where inventory is stored                      |
| quantity\_on\_hand  | INTEGER   | Total physical inventory                        | Current stock level                            |
| quantity\_allocated | INTEGER   | Reserved inventory                              | Stock allocated to pending orders              |
| quantity\_available | INTEGER   | Available inventory                             | Actual available stock (on_hand - allocated)   |
| restock\_level      | INTEGER   | Minimum threshold                               | Threshold for reordering                       |
| restock\_quantity   | INTEGER   | Reorder amount                                  | Standard reorder quantity                      |
| days\_of\_supply    | FLOAT     | Inventory runway                                | Estimated days until stockout based on sales   |
| last\_restock\_date | DATE      | Last restock date                               | Date of last inventory restock                 |
| next\_delivery\_date| DATE      | Next expected delivery                          | Expected date of next delivery (sometimes NULL)|
| sales\_velocity     | FLOAT     | Base sales velocity                             | Base rate of sales (units per day)             |
| last\_sale\_date    | DATE      | Date of last sale                               | When item was last sold                        |

---

#### `raw_marketing_spend` (enhanced with campaign details)

| Column           | Type      | Description                                     | Notes                                           |
| ---------------- | --------- | ----------------------------------------------- | ----------------------------------------------- |
| spend\_id        | STRING    | Unique spend record identifier                  | PK                                              |
| channel          | STRING    | Marketing channel                               | `google`, `facebook`, `email`                   |
| campaign\_name   | STRING    | Campaign name                                   | Should match utm\_campaign in other tables      |
| campaign\_source | STRING    | Campaign source                                 | Should match utm\_source in other tables        |
| campaign\_medium | STRING    | Campaign medium                                 | Should match utm\_medium in other tables        |
| spend\_date      | DATE      | Date of marketing spend                         | Daily spend records                             |
| spend\_amount    | NUMERIC   | Amount spent                                    | Daily spend amount                              |
| impressions      | INTEGER   | Number of ad impressions                        | How many times ads were shown                   |
| clicks           | INTEGER   | Number of ad clicks                             | How many times ads were clicked                 |
| campaign\_details | RECORD   | Detailed campaign information                   | Nested record with campaign specifics           |
| campaign\_details.audience | RECORD | Audience targeting information           | Nested record with audience details             |
| campaign\_details.audience.targeting | ARRAY<STRING> | Targeting criteria      | e.g. ['Interest', 'Lookalike', 'Retargeting']   |
| campaign\_details.audience.demographics | RECORD | Demographic targeting       | Nested record with demographic details          |
| campaign\_details.audience.demographics.age\_ranges | ARRAY<STRING> | Target ages | e.g. ['18-24', '25-34', '35-44']            |
| campaign\_details.audience.demographics.genders | ARRAY<STRING> | Target genders | e.g. ['Male', 'Female', 'Unknown']           |
| campaign\_details.audience.demographics.locations | ARRAY<STRING> | Target locations | e.g. ['New York', 'California']          |
| campaign\_details.creative | RECORD | Creative information                     | Nested record with creative details             |
| campaign\_details.creative.ad\_type | STRING | Type of ad                      | e.g. 'Image', 'Video', 'Carousel'              |
| campaign\_details.creative.ad\_format | STRING | Format of ad                  | e.g. 'Banner', 'Native', 'Story'               |
| campaign\_details.creative.ad\_size | STRING | Size of ad                      | e.g. '300x250', '728x90'                       |
| campaign\_details.creative.ad\_copy | STRING | Ad copy text                    | Main text used in the ad                        |

---

#### `raw_sessions` (enhanced with detailed event tracking)

| Column         | Type          | Description                                     | Notes                                           |
| -------------- | ------------- | ----------------------------------------------- | ----------------------------------------------- |
| session\_id    | STRING        | Unique session identifier                       | PK                                              |
| customer\_id   | STRING        | Customer identifier                             | FK to raw\_customers (sometimes NULL for guest) |
| session\_ts    | TIMESTAMP     | Session start time                              | Session start timestamp                         |
| device\_type   | STRING        | Device used                                     | 'mobile', 'desktop', 'tablet'                   |
| browser        | STRING        | Browser used                                    | Browser information                             |
| ip\_address    | STRING        | IP address                                      | Sometimes malformed                             |
| utm\_source    | STRING        | Traffic source                                  | Marketing attribution source (sometimes NULL)   |
| utm\_campaign  | STRING        | Marketing campaign                              | Campaign name (sometimes NULL)                  |
| utm\_medium    | STRING        | Marketing medium                                | Medium (sometimes NULL)                         |
| session\_attributes | RECORD   | Session-level attributes                        | Nested record with session metrics              |
| session\_attributes.duration\_seconds | INTEGER | Session duration               | Total time spent in session                     |
| session\_attributes.pages\_viewed | INTEGER | Number of pages viewed             | Total page views in session                     |
| session\_attributes.entry\_page | STRING | First page viewed                     | Landing page URL                                |
| session\_attributes.exit\_page | STRING | Last page viewed                       | Exit page URL                                   |
| session\_attributes.customer\_segment | STRING | Customer segment                | e.g. 'New', 'Returning', 'VIP'                  |
| session\_attributes.new\_vs\_returning | STRING | New or returning               | 'New' or 'Returning' visitor                    |
| events         | ARRAY<RECORD> | Session events                                  | Array of user events                            |
| events.event\_type | STRING    | Type of event                                   | e.g. 'page_view', 'add_to_cart', 'purchase'    |
| events.event\_ts   | TIMESTAMP | When event occurred                             | Event timestamp                                 |
| events.product\_id | STRING    | Product involved (if applicable)                | FK to raw\_products, NULL for non-product events|
| events.variant\_id | STRING    | Variant involved (if applicable)                | FK to raw\_products.variants                    |
| events.page\_url   | STRING    | URL of page where event occurred                | Full URL path                                   |
| events.event\_properties | RECORD | Event-specific properties                    | Nested record with event details                |
| events.event\_properties.view\_details | RECORD | Product view details           | For product_view events                         |
| events.event\_properties.view\_details.time\_spent | INTEGER | View duration     | Seconds spent viewing product                   |
| events.event\_properties.view\_details.scrolled\_percent | INTEGER | Scroll depth| How far down page was scrolled                  |
| events.event\_properties.view\_details.images\_viewed | INTEGER | Images viewed  | Number of product images viewed                 |
| events.event\_properties.view\_details.variant\_switches | INTEGER | Variant switches | Number of variant selections               |
| events.event\_properties.cart\_details | RECORD | Cart action details            | For add_to_cart events                          |
| events.event\_properties.cart\_details.quantity | INTEGER | Quantity added       | Number of items added                           |
| events.event\_properties.cart\_details.price | NUMERIC | Item price              | Price of added item                             |
| events.event\_properties.cart\_details.added\_from | STRING | Source location    | e.g. 'PDP', 'Quick view', 'Recommendation'      |
| events.event\_properties.cart\_details.cart\_value | NUMERIC | Cart total        | Total cart value after addition                 |
| events.event\_properties.cart\_details.cart\_size | INTEGER | Cart size          | Total items in cart after addition              |
| events.event\_properties.checkout\_details | RECORD | Checkout details           | For checkout events                             |
| events.event\_properties.checkout\_details.step | STRING | Checkout step         | e.g. 'Information', 'Shipping', 'Payment'       |
| events.event\_properties.checkout\_details.payment\_method | STRING | Payment method | Selected payment method                     |
| events.event\_properties.checkout\_details.shipping\_method | STRING | Shipping method | Selected shipping method                  |
| events.event\_properties.checkout\_details.promo\_applied | BOOLEAN | Promo usage| Whether promo code was applied                  |
| events.event\_properties.checkout\_details.cart\_abandonment | BOOLEAN | Abandonment | Whether checkout was abandoned              |
| events.event\_properties.funnel\_position | RECORD | Funnel position            | For all events                                   |
| events.event\_properties.funnel\_position.step\_name | STRING | Funnel step      | Name of funnel step                             |
| events.event\_properties.funnel\_position.step\_number | INTEGER | Step number   | Position in funnel sequence                     |
| events.event\_properties.funnel\_position.previous\_step | STRING | Previous step| Previous funnel step                            |
| events.event\_properties.funnel\_position.next\_step | STRING | Next step        | Next funnel step                                |
| events.event\_properties.funnel\_position.time\_since\_previous | INTEGER | Time since last step | Seconds since previous step    |

---

### **Project Requirements**

#### **Recommended Approach**

This project requires a structured, methodical approach to data warehouse development. Follow these steps:

1. **Analysis Phase**
   * Study the raw data schemas and understand the relationships between tables
   * Document the business requirements and translate them into data modeling needs
   * Identify data quality issues that need to be addressed
   * Map out entity relationships and determine appropriate grain for each model
   * Plan your dimensional model with facts and dimensions appropriate to the business questions

2. **Design Phase**
   * Design a multi-layered dbt project with clear separation of concerns:
     * **Staging Layer**: Clean and standardize source data
     * **Intermediate Layer**: Handle complex transformations and business logic
     * **Core Layer**: Build dimensional models (facts and dimensions)
     * **Mart Layer**: Create business-specific analytical views
   * Document your design decisions and assumptions
   * Create a data dictionary for your final models

3. **Implementation Phase**
   * Develop models incrementally, testing at each stage
   * Handle the complex nested data structures methodically
   * Implement appropriate tests to ensure data quality
   * Optimize query performance where necessary
   * Document your code thoroughly

4. **Validation Phase**
   * Verify that your models correctly transform the source data
   * Ensure business requirements are met
   * Validate results against expected outcomes
   * Test edge cases and error handling

5. **Presentation Phase**
   * Prepare queries that answer the key business questions
   * Create visualizations if appropriate
   * Document your approach and findings
   * Be prepared to explain your design decisions

#### **Technical Requirements**

* **Data Transformation**
  * Flatten deeply nested arrays and records while preserving relationships
  * Handle multi-level nesting (arrays within arrays, records within records)
  * Standardize column names and data types
  * Clean data issues (duplicates, invalid formats, timezone inconsistencies)
  * Calculate derived metrics from raw data (don't rely on pre-calculated fields)

* **dbt Best Practices**
  * Organize your project following dbt best practices
  * Create reusable macros for common transformations
  * Implement comprehensive testing
  * Document your models, tests, and macros
  * Use packages like `dbt_utils` and `dbt-expectations` where appropriate
  * Consider implementing custom macros or materializations for complex transformations

* **Deliverables**
  * Complete dbt project with all necessary models
  * Documentation of your approach and design decisions
  * SQL queries that answer the key business questions:
    * Which product variants have the highest margin and conversion rate? (calculate margin and conversion metrics)
    * What is the customer lifetime value by acquisition channel and cohort? (calculate LTV from order history)
    * How does the purchase funnel differ between new and returning customers? (derive funnel conversion rates)
    * Which product attributes most strongly correlate with repeat purchases? (analyze attribute correlation)
    * How does inventory turnover vary by product category and variant? (calculate turnover metrics)
  * Looker Studio dashboard visualizing key metrics and insights from your analysis
  * Presentation of your findings and recommendations

---

### **Data Generation**

To generate sample datasets for this project:

1. **Setup Environment**
   ```bash
   # Create and activate a virtual environment (optional)
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   
   # Install dependencies using uv
   pip install uv
   uv pip install -r requirements.txt
   ```

2. **Generate Data**
   ```bash
   python generate_data.py
   ```

3. **Load to BigQuery**
   - Create a dataset in BigQuery
   - Upload each JSONL file from the `data/` directory to create tables
   - Ensure schema autodetection is enabled

The generated data includes:
- Complex nested structures (arrays within records, records within arrays)
- Multiple levels of nesting that require recursive flattening
- Realistic business patterns that reflect ecommerce operations
- Intentional data quality issues that need to be addressed
- Relationships between entities that must be preserved during transformation
- Raw data points that require calculation of business metrics
- Attribution data spread across multiple tables that must be joined and analyzed
