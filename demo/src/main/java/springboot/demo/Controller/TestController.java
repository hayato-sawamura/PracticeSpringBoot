package springboot.demo.Controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;


@Controller
public class TestController {

  @GetMapping("/test")  
  public String showTest() {
    return "test";
  }

}