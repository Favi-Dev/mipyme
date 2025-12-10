class VitrinaData {
  static String name = 'Zapatería Los Robles';
  static String category = 'Comercio/retail'; // Categorías: Comercio/retail, Alimentos y gastronomía, Servicios profesionales, Salud, belleza y bienestar, Oficios y manufactura, Educación y cultura, Transporte y logística
  static String description = 'Calzado artesanal de cuero legítimo, hecho a mano con tradición y estilo. Encuentra botas, zapatos formales y casuales para toda ocasión. Reparación y cuidado del calzado.';
  static String coverImageUrl = 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=800&q=80';
  static String logoUrl = 'assets/images/logo el roble calzados.jpg';

  static void setCategory(String newCategory) {
    category = newCategory;
    // Reset donation data
    donationGoal = 0;
    currentDonations = 0;
    donationAlias = '';
    donationCbu = '';

    switch (newCategory) {
      case 'Comercio/retail':
        name = 'Zapatería Los Robles';
        description = 'Calzado artesanal de cuero legítimo, hecho a mano con tradición y estilo.';
        coverImageUrl = 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'assets/images/logo el roble calzados.jpg';
        break;
      case 'Alimentos y gastronomía':
        name = 'Cafetería El Grano';
        description = 'El mejor café de grano y pastelería casera en un ambiente acogedor.';
        coverImageUrl = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=200&q=80';
        break;
      case 'Servicios profesionales':
        name = 'Estudio Jurídico Silva';
        description = 'Asesoría legal integral para empresas y personas. Expertos en derecho laboral.';
        coverImageUrl = 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=200&q=80';
        break;
      case 'Salud, belleza y bienestar':
        name = 'Farmayuda';
        description = '¡Bienvenidos a Farmayuda! tu farmacia céntrica y económica con productos naturales y novedosos para tu bienestar. ¡Cuida de ti con nosotros!';
        coverImageUrl = 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'assets/images/logo farmayuda.jpg';
        break;
      case 'Oficios y manufactura':
        name = 'Muebles Rusticos Chile';
        description = 'Fabricación de muebles a medida en maderas nativas. Restauración y barnizado.';
        coverImageUrl = 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=200&q=80';
        break;
      case 'Educación y cultura':
        name = 'Fundación Los Robles';
        description = 'Fundación sin fines de lucro, que busca impulsar el reciclaje y el apoyo a bancos de trabajo para adultos mayores';
        coverImageUrl = 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'assets/images/Logo los robles.jpg';
        // Donation data
        donationGoal = 5000000;
        currentDonations = 1250000;
        donationAlias = 'fundacion.losrobles.donar';
        donationCbu = '0000003100000000000000';
        break;
      case 'Transporte y logística':
        name = 'Fletes Rápidos Santiago';
        description = 'Servicio de mudanzas y fletes dentro y fuera de Santiago. Carga asegurada.';
        coverImageUrl = 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=200&q=80';
        break;
      case 'Metamorfosis':
        name = 'Metamorfosis';
        category = 'Reciclaje Textil'; // Override category display
        description = 'Reciclaje Textil / Slow Fashion. Chile 🇨🇱. Piezas Únicas ♻️. Transformamos prendas olvidadas en tesoros únicos.';
        coverImageUrl = 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=800&q=80';
        logoUrl = 'assets/images/metamorfosis.jpg';
        break;
    }
  }
  static String hours = 'Lun-Vie: 10:00 - 19:00\nSáb: 10:00 - 14:00';
  static String location = 'Calle Los Robles 456, Providencia';
  static String webUrl = 'www.zapaterialosrobles.cl';
  static String instagramHandle = '@zapaterialosrobles';
  static String whatsappNumber = '+56987654321';
  static int supporterCount = 342; // Mock counter for "S+" supporters

  // Donation fields
  static double donationGoal = 0;
  static double currentDonations = 0;
  static String donationAlias = '';
  static String donationCbu = '';
  static bool get isFoundation => category == 'Educación y cultura' || name.toLowerCase().contains('fundación');
}
